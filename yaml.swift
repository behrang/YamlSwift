import Foundation

enum TokenType: String, Printable {
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
  case End = "end"

  var description: String {
    return self.toRaw()
  }
}

typealias TokenPattern = (type: TokenType, pattern: String)
typealias TokenMatch = (type: TokenType, match: String)

let finish = "(?=\\s*(\\s#[^\\n]*)?(\\n|$))"
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

    case .End:
      return .Null

    }
  }
}

public enum Yaml: Printable {

  case Null
  case Bool(Swift.Bool)
  case Int(Swift.Int)
  case Float(Swift.Float)
  case Invalid(String)

  public var description: String {
    switch self {
    case .Null:
      return "Null"
    case .Bool(let b):
      return "Bool: \(b)"
    case .Int(let i):
      return "Int: \(i)"
    case .Float(let f):
      return "Float: \(f)"
    case .Invalid(let e):
      return "Invalid: \(e)"
    default:
      return "*Unknown*"
    }
  }

  public static func load (text: String) -> Yaml {
    let result = tokenize(text)
    if let error = result.error {
      println("Error: \(error)")
      return .Invalid(error)
    }
    let ret = Parser(result.tokens!).parse()
    println(ret)
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

  case .Invalid(let lv):
    switch rhs {
    case .Invalid(let rv):
      return lv == rv
    default:
      return false
    }

  default:
    return false
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
