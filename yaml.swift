import Foundation

enum TokenType: Swift.String, Printable {
  case Comment = "comment"
  case Space = "space"
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
  (.Key, "^\\w[\\w -]*(?= *: )"),
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
  next:
  while countElements(text) > 0 {
    for tokenPattern in tokenPatterns {
      if let range = text.rangeOfString(tokenPattern.pattern, options: .RegularExpressionSearch) {
        matches.append(TokenMatch(tokenPattern.type, text.substringWithRange(range)))
        text = text.substringFromIndex(range.endIndex)
        continue next
      }
    }
    return (context(text), nil)
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

  func peek() -> TokenMatch {
    return tokens[index]
  }

  func advance() -> TokenMatch {
    let r = tokens[index]
    index += 1
    return r
  }

  func accept(type: TokenType) -> Bool {
    if peek().type == type {
      advance()
      return true
    }
    return false
  }

  func expect(type: TokenType, message: String) -> String? {
    if peek().type == type {
      advance()
      return nil
    }
    return "\(message), \(context(peek().match))"
  }

  func ignoreSpace() {
    while peek().type == .Space {
      advance()
    }
  }

  func parse() -> Yaml {
    switch peek().type {

    case .Comment, .Space:
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
      return .Int(m.integerValue) // what about overflow?

    case .IntOct:
      let m = advance().match.stringByReplacingOccurrencesOfString("0o", withString: "")
      return .Int(parseInt(m, radix: 8))

    case .IntHex:
      let m = advance().match.stringByReplacingOccurrencesOfString("0x", withString: "")
      return .Int(parseInt(m, radix: 16))

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

    case .OpenSB:
      return parseFlowSeq()

    case .OpenCB:
      return parseFlowMap()

    case .StringDQ, .StringSQ:
      let m = advance().match
      let r = Range(start: Swift.advance(m.startIndex, 1), end: Swift.advance(m.endIndex, -1))
      return .String(m.substringWithRange(r))

    case .String:
      return .String(advance().match)

    case .End:
      return .Null

    default:
      return .Invalid(context(peek().match))

    }
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
      let v = parse() // what about two consecutive commas?
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
      ignoreSpace()
      if map.count > 0 {
        if let error = expect(.Comma, message: "expected comma") {
          return .Invalid(error)
        }
      }
      ignoreSpace()
      var k: String = ""
      switch peek().type {
      case .Key:
        k = advance().match
      case .KeyDQ, .KeySQ:
        let m = advance().match
        let r = Range(start: Swift.advance(m.startIndex, 1), end: Swift.advance(m.endIndex, -1))
        k = m.substringWithRange(r)
      default:
        break // what if not?
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

  public static func load (text: Swift.String) -> Yaml {
    let result = tokenize(text)
    if let error = result.error {
      // println("Error: \(error)")
      return .Invalid(error)
    }
    let ret = Parser(result.tokens!).parse()
    // println(ret)
    return ret
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

func parseInt(s: String, #radix: Int) -> Int {
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
