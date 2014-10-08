import Foundation

enum TokenType: Swift.String, Printable {
  case Comment = "comment"
  case Space = "space"
  case BlankLine = "blankline"
  case NewLine = "newline"
  case Indent = "indent"
  case Dedent = "dedent"
  case Null = "null"
  case True = "true"
  case False = "false"
  case InfinityP = "+infinity"
  case InfinityN = "-infinity"
  case NaN = "nan"
  case Float = "float"
  case Int = "int"
  case IntOct = "int-oct"
  case IntHex = "int-hex"
  case Comma = ","
  case OpenSB = "["
  case CloseSB = "]"
  case Dash = "-"
  case OpenCB = "{"
  case CloseCB = "}"
  case Key = "key"
  case KeyDQ = "key-dq"
  case KeySQ = "key-sq"
  case Colon = ":"
  case StringDQ = "string-dq"
  case StringSQ = "string-sq"
  case String = "string"
  case End = "end"

  var description: Swift.String {
    return self.toRaw()
  }
}

typealias TokenPattern = (type: TokenType, pattern: String)
typealias TokenMatch = (type: TokenType, match: String)

let finish = "(?= *(,|\\]|\\}|( #[^\\n]*)?(\\n|$)))"
let tokenPatterns: [TokenPattern] = [
  (.Comment, "^#[^\\n]*"),
  (.Space, "^ +"),
  (.BlankLine, "^\\n *(#[^\\n]*)?(?=\\n|$)"),
  (.NewLine, "^\\n *"),
  (.Dash, "^-( +|(?=\\n))"),
  (.Null, "^(null|Null|NULL|~)\(finish)"),
  (.True, "^(true|True|TRUE)\(finish)"),
  (.False, "^(false|False|FALSE)\(finish)"),
  (.InfinityP, "^\\+?\\.(inf|Inf|INF)\(finish)"),
  (.InfinityN, "^-\\.(inf|Inf|INF)\(finish)"),
  (.NaN, "^\\.(nan|NaN|NAN)\(finish)"),
  (.Int, "^[-+]?[0-9]+\(finish)"),
  (.IntOct, "^0o[0-7]+\(finish)"),
  (.IntHex, "^0x[0-9a-fA-F]+\(finish)"),
  (.Float, "^[-+]?(\\.[0-9]+|[0-9]+(\\.[0-9]*)?)([eE][-+]?[0-9]+)?\(finish)"),
  (.Comma, "^,"),
  (.OpenSB, "^\\["),
  (.CloseSB, "^\\]"),
  (.OpenCB, "^\\{"),
  (.CloseCB, "^\\}"),
  (.Key, "^\\w[\\w -]*(?= *:( |\\n))"),
  (.KeyDQ, "^\".*?\"(?= *:)"),
  (.KeySQ, "^'.*?'(?= *:)"),
  (.Colon, "^:"),
  (.StringDQ, "^\".*?\""),
  (.StringSQ, "^'.*?'"),
  (.String, "^.*?\(finish)"),
]

func context (var text: String) -> String {
  let endIndex = advance(text.startIndex, 25, text.endIndex)
  text = text.substringToIndex(endIndex)
  text = text.stringByReplacingOccurrencesOfString("\n", withString: "\\n")
  text = text.stringByReplacingOccurrencesOfString("\"", withString: "\\\"")
  return "near \"\(text)\""
}

func tokenize (var text: String) -> (error: String?, tokens: [TokenMatch]?) {
  var matches: [TokenMatch] = []
  var indents = [0]
  next:
  while countElements(text) > 0 {
    for tokenPattern in tokenPatterns {
      if let range = text.rangeOfString(tokenPattern.pattern, options: .RegularExpressionSearch) {
        switch tokenPattern.type {
        case .NewLine:
          let match = text.substringWithRange(range)
          let spaces = countElements(match.substringFromIndex(advance(match.startIndex, 1)))
          if spaces > indents.last! {
            indents.append(spaces)
            matches.append(TokenMatch(.Indent, match))
          } else if spaces == indents.last! {
            matches.append(TokenMatch(.NewLine, match))
          } else {
            while spaces < indents.last! {
              indents.removeLast()
              matches.append(TokenMatch(.Dedent, ""))
            }
          }
        case .Dash:
          let match = text.substringWithRange(range)
          let dashIndex = advance(match.startIndex, 1)
          let indent = countElements(match)
          indents.append(indents.last! + indent)
          matches.append(TokenMatch(.Dash, match.substringToIndex(dashIndex)))
          matches.append(TokenMatch(.Indent, match.substringFromIndex(dashIndex)))
        default:
          matches.append(TokenMatch(tokenPattern.type, text.substringWithRange(range)))
        }
        text = text.substringFromIndex(range.endIndex)
        continue next
      }
    }
    return (context(text), nil)
  }
  while indents.count > 1 {
    indents.removeLast()
    matches.append((.Dedent, ""))
  }
  matches.append((.End, ""))
  return (nil, matches)
}

class Parser {
  let tokens: [TokenMatch]
  var index: Int = 0

  init(_ tokens: [TokenMatch]) {
    self.tokens = tokens
  }

  func peek () -> TokenMatch {
    return tokens[index]
  }

  func advance () -> TokenMatch {
    let r = tokens[index]
    index += 1
    return r
  }

  func accept (type: TokenType) -> Bool {
    if peek().type == type {
      advance()
      return true
    }
    return false
  }

  func expect (type: TokenType, message: String) -> String? {
    if peek().type == type {
      advance()
      return nil
    }
    return "\(message), \(context(buildContext()))"
  }

  func buildContext (count: Int = 25) -> String {
    var text = ""
    while peek().type != .End {
      text += advance().match
      if countElements(text) >= count {
        break
      }
    }
    return text
  }

  func ignoreSpace () {
    while contains([.Comment, .Space, .BlankLine, .NewLine], peek().type) {
      advance()
    }
  }

  func ignoreWhiteSpace () {
    while contains([.Comment, .Space, .BlankLine, .NewLine, .Indent, .Dedent], peek().type) {
      advance()
    }
  }

  func parse () -> Yaml {
    switch peek().type {

    case .Comment, .Space, .BlankLine, .NewLine:
      advance()
      return parse()

    case .Null:
      advance()
      return .Null

    case .True:
      advance()
      return .Bool(true)

    case .False:
      advance()
      return .Bool(false)

    case .Int:
      let m = advance().match as NSString
      return .Int(m.integerValue) // will be between Int.min and Int.max

    case .IntOct:
      let m = advance().match.stringByReplacingOccurrencesOfString("0o", withString: "")
      return .Int(parseInt(m, radix: 8)) // will throw runtime error if overflows

    case .IntHex:
      let m = advance().match.stringByReplacingOccurrencesOfString("0x", withString: "")
      return .Int(parseInt(m, radix: 16)) // will throw runtime error if overflows

    case .InfinityP:
      advance()
      return .Float(Float.infinity)

    case .InfinityN:
      advance()
      return .Float(-Float.infinity)

    case .NaN:
      advance()
      return .Float(Float.NaN)

    case .Float:
      let m = advance().match as NSString
      return .Float(m.floatValue)

    case .Dash:
      return parseBlockSeq()

    case .OpenSB:
      return parseFlowSeq()

    case .OpenCB:
      return parseFlowMap()

    case .KeyDQ, .KeySQ, .Key:
      return parseBlockMap()

    case .Indent:
      accept(.Indent)
      let result = parse()
      if let error = expect(.Dedent, message: "expected dedent") {
        return .Invalid(error)
      }
      return result

    case .StringDQ, .StringSQ:
      let m = advance().match
      let r = Range(start: Swift.advance(m.startIndex, 1), end: Swift.advance(m.endIndex, -1))
      return .String(m.substringWithRange(r))

    case .String:
      return .String(advance().match)

    case .End:
      return .Null

    default:
      return .Invalid(context(buildContext()))

    }
  }

  func parseBlockSeq () -> Yaml {
    var seq: [Yaml] = []
    while accept(.Dash) {
      accept(.Indent)
      ignoreSpace()
      let v = parse()
      ignoreSpace()
      if let error = expect(.Dedent, message: "expected dedent after dash indent") {
        return .Invalid(error)
      }
      switch v {
      case .Invalid:
        return v
      default:
        seq.append(v)
      }
      ignoreSpace()
    }
    return .Seq(seq)
  }

  func parseFlowSeq () -> Yaml {
    var seq: [Yaml] = []
    accept(.OpenSB)
    while !accept(.CloseSB) {
      ignoreSpace()
      if seq.count > 0 {
        if let error = expect(.Comma, message: "expected comma") {
          return .Invalid(error)
        }
      }
      ignoreSpace()
      let v = parse()
      switch v {
      case .Invalid:
        return v
      default:
        seq.append(v)
      }
      ignoreSpace()
    }
    return .Seq(seq)
  }

  func parseFlowMap () -> Yaml {
    var map: [String: Yaml] = [:]
    accept(.OpenCB)
    while !accept(.CloseCB) {
      ignoreWhiteSpace()
      if map.count > 0 {
        if let error = expect(.Comma, message: "expected comma") {
          return .Invalid(error)
        }
      }
      ignoreWhiteSpace()
      var k = ""
      switch peek().type {
      case .Key:
        k = advance().match
      case .KeyDQ, .KeySQ:
        k = unwrapQuotedString(advance().match)
      default:
        return .Invalid(expect(.Key, message: "expected key")!)
      }
      if let error = expect(.Colon, message: "expected colon") {
        return .Invalid(error)
      }
      let v = parse()
      switch v {
      case .Invalid:
        return v
      default:
        map.updateValue(v, forKey: k)
      }
      ignoreWhiteSpace()
    }
    return .Map(map)
  }

  func parseBlockMap () -> Yaml {
    var map: [String: Yaml] = [:]
    while contains([.Key, .KeyDQ, .KeySQ], peek().type) {
      var k = ""
      switch peek().type {
      case .Key:
        k = advance().match
      case .KeyDQ, .KeySQ:
        k = unwrapQuotedString(advance().match)
      default:
        return .Invalid(expect(.Key, message: "expected key")!)
      }
      if let error = expect(.Colon, message: "expected colon") {
        return .Invalid(error)
      }
      ignoreSpace()
      var v: Yaml
      if accept(.Indent) {
        v = parse()
        if let error = expect(.Dedent, message: "expected dedent") {
          return .Invalid(error)
        }
      } else {
        v = parse()
      }
      switch v {
      case .Invalid:
        return v
      default:
        map.updateValue(v, forKey: k)
      }
      ignoreSpace()
    }
    return .Map(map)
  }
}

public enum Yaml: Printable {

  case Null
  case Bool(Swift.Bool)
  case Int(Swift.Int)
  case Float(Swift.Float)
  case String(Swift.String)
  case Seq([Yaml])
  case Map([Swift.String: Yaml]) // todo: change key type to Yaml
  case Invalid(Swift.String)

  public static func load (text: Swift.String) -> Yaml {
    let result = tokenize(text)
    if let error = result.error {
      // println("Error: \(error)")
      return .Invalid(error)
    }
    // println(result.tokens!)
    let parser = Parser(result.tokens!)
    let value = parser.parse()
    parser.ignoreSpace()
    if let error = parser.expect(.End, message: "expected end") {
      return .Invalid(error)
    }
    // println(value)
    return value
  }

  public var bool: Swift.Bool? {
    switch self {
    case .Bool(let b):
      return b
    default:
      return nil
    }
  }

  public var int: Swift.Int? {
    switch self {
    case .Int(let i):
      return i
    case .Float(let f):
      if Swift.Float(Swift.Int(f)) == f {
        return Swift.Int(f)
      } else {
        return nil
      }
    default:
      return nil
    }
  }

  public var float: Swift.Float? {
    switch self {
    case .Float(let f):
      return f
    case .Int(let i):
      return Swift.Float(i)
    default:
      return nil
    }
  }

  public var string: Swift.String? {
    switch self {
    case .String(let s):
      return s
    default:
      return nil
    }
  }

  public var seq: [Yaml]? {
    switch self {
    case .Seq(let seq):
      return seq
    default:
      return nil
    }
  }

  public var map: [Swift.String: Yaml]? {
    switch self {
    case .Map(let map):
      return map
    default:
      return nil
    }
  }

  public var description: Swift.String {
    switch self {
    case .Null:
      return "Null"
    case .Bool(let b):
      return "Bool(\(b))"
    case .Int(let i):
      return "Int(\(i))"
    case .Float(let f):
      return "Float(\(f))"
    case .String(let s):
      return "String(\(s))"
    case .Seq(let s):
      return "Seq(\(s))"
    case .Map(let m):
      return "Map(\(m))"
    case .Invalid(let e):
      return "Invalid(\(e))"
    }
  }
}

public func == (lhs: Yaml, rhs: Yaml) -> Bool {
  switch lhs {

  case .Null:
    switch rhs {
    case .Null:
      return true
    default:
      return false
    }

  case .Bool(let lv):
    switch rhs {
    case .Bool(let rv):
      return lv == rv
    default:
      return false
    }

  case .Int(let lv):
    switch rhs {
    case .Int(let rv):
      return lv == rv
    default:
      return false
    }

  case .Float(let lv):
    switch rhs {
    case .Float(let rv):
      return lv == rv || lv.isNaN && rv.isNaN
    default:
      return false
    }

  case .String(let lv):
    switch rhs {
    case .String(let rv):
      return lv == rv
    default:
      return false
    }

  case .Seq(let lv):
    switch rhs {
    case .Seq(let rv) where lv.count == rv.count:
      for i in 0..<lv.count {
        if lv[i] != rv[i] {
          return false
        }
      }
      return true
    default:
      return false
    }

  case .Map(let lv):
    switch rhs {
    case .Map(let rv) where lv.count == rv.count:
      for (k, v) in lv {
        if rv[k] == nil || rv[k]! != v {
          return false
        }
      }
      return true
    default:
      return false
    }

  case .Invalid(let lv):
    switch rhs {
    case .Invalid(let rv):
      return lv == rv
    default:
      return false
    }

  }
}

public func != (lhs: Yaml, rhs: Yaml) -> Bool {
  return !(lhs == rhs)
}

func parseInt (s: String, #radix: Int) -> Int {
  return reduce(lazy(s.unicodeScalars).map({
    c in
    switch c {
    case "0"..."9":
      return c.value - "0".value
    case "a"..."z":
      return c.value - "a".value + 10
    case "A"..."Z":
      return c.value - "A".value + 10
    default:
      fatalError("invalid digit")
    }
  }), 0, {$0 * radix + $1})
}

func unwrapQuotedString (s: String) -> String {
  return s.substringWithRange(Range(start: advance(s.startIndex, 1), end: advance(s.endIndex, -1)))
}
