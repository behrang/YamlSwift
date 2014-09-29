import Foundation

enum TokenType: String, Printable {
  case Comment = "comment"
  case Null = "null"
  case True = "true"
  case False = "false"

  var description: String {
    return self.toRaw()
  }
}

typealias TokenPattern = (type: TokenType, pattern: String)
typealias TokenMatch = (type: TokenType, match: String)

let tokenPatterns: [TokenPattern] = [
  (.Comment, "^#[^\\n]*"),
  (.Null, "^(null|Null|NULL|~|$)"),
  (.True, "^(true|True|TRUE)\\s*(\\s#[^\\n]*)?(?=\\n|$)"),
  (.False, "^(false|False|FALSE)\\s*(\\s#[^\\n]*)?(?=\\n|$)"),
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
  return (nil, matches)
}

class Parser {
  let tokens: [TokenMatch]
  var index: Int = 0

  init(_ tokens: [TokenMatch]) {
    self.tokens = tokens
  }

  func peekType() -> TokenType {
    return tokens[index].type
  }

  func parse() -> Yaml {
    while index < tokens.endIndex {
      let nextType = peekType()

      if nextType == .Comment {
        index += 1
        continue
      }

      if nextType == .Null {
        index += 1
        return .Null
      }

      if nextType == .True {
        return .Bool(true)
      }

      if nextType == .False {
        return .Bool(false)
      }

    }
    return .Null
  }
}

public enum Yaml: Printable {

  case Null
  case Bool(Swift.Bool)
  case Invalid(String)

  public var description: String {
    switch self {
    case .Null:
      return "Null"
    case .Bool(let b):
      return "Bool: \(b)"
    case .Invalid(let e):
      return "Invalid: \(e)"
    default:
      return "*Unknown*"
    }
  }

  public static func load (text: String) -> Yaml {
    let result = tokenize(text)
    if let error = result.error {
      println(error)
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
