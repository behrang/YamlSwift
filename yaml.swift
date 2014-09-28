import Foundation

enum TokenType: String, Printable {
  case Comment = "comment"
  case Null = "null"

  var description: String {
    return self.toRaw()
  }
}

typealias TokenPattern = (type: TokenType, pattern: String)
typealias TokenMatch = (type: TokenType, match: String)

let tokenPatterns: [TokenPattern] = [
  (.Comment, "^#[^\\n]*"),
  (.Null, "^(null|Null|NULL|~|$)")
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
  var tokens: [TokenMatch]

  init(_ tokens: [TokenMatch]) {
    self.tokens = tokens
  }

  func parse() -> Yaml {
    return .Null
  }
}

public enum Yaml {

  case Null
  case Invalid(String)

  public static func load (text: String) -> Yaml {
    let result = tokenize(text)
    if let error = result.error {
      return .Invalid(error)
    }
    return Parser(result.tokens!).parse()
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

  case .Invalid(let ls):
    switch rhs {
    case .Invalid(let rs):
      return ls == rs
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
