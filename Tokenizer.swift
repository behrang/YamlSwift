enum TokenType: Swift.String, Printable {
  case YamlDirective = "%YAML"
  case DocStart = "doc-start"
  case DocEnd = "doc-end"
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
  case Double = "double"
  case Int = "int"
  case IntOct = "int-oct"
  case IntHex = "int-hex"
  case IntSex = "int-sex"
  case Anchor = "&"
  case Alias = "*"
  case Comma = ","
  case OpenSB = "["
  case CloseSB = "]"
  case Dash = "-"
  case OpenCB = "{"
  case CloseCB = "}"
  case Key = "key"
  case KeyDQ = "key-dq"
  case KeySQ = "key-sq"
  case QuestionMark = "?"
  case Colon = ":"
  case Literal = "|"
  case Folded = ">"
  case StringDQ = "string-dq"
  case StringSQ = "string-sq"
  case String = "string"
  case End = "end"

  var description: Swift.String {
    return self.rawValue
  }
}

typealias TokenPattern = (type: TokenType, pattern: String)
typealias TokenMatch = (type: TokenType, match: String)

let finish = "(?= *(,|\\]|\\}|( #[^\\n]*)?(\\n|$)))"
let tokenPatterns: [TokenPattern] = [
  (.YamlDirective, "^%YAML(?= )"),
  (.DocStart, "^---"),
  (.DocEnd, "^\\.\\.\\."),
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
  (.IntSex, "^[0-9]{2}(:[0-9]{2})+\(finish)"),
  (.Double, "^[-+]?(\\.[0-9]+|[0-9]+(\\.[0-9]*)?)([eE][-+]?[0-9]+)?\(finish)"),
  (.Anchor, "^&\\w+"),
  (.Alias, "^\\*\\w+"),
  (.Comma, "^,"),
  (.OpenSB, "^\\["),
  (.CloseSB, "^\\]"),
  (.OpenCB, "^\\{"),
  (.CloseCB, "^\\}"),
  (.Key, "^\\w( *[\\w-]+)*(?= *:( |\\n))"),
  (.KeyDQ, "^\".*?\"(?= *:)"),
  (.KeySQ, "^'.*?'(?= *:)"),
  (.QuestionMark, "^\\?( +|(?=\\n))"),
  (.Colon, "^:"),
  (.Literal, "^\\|([-+]|[1-9]|[-+][1-9]|[1-9][-+])? *( #[^\\n]*)?(\\n|$)"),
  (.Folded, "^>([-+]|[1-9]|[-+][1-9]|[1-9][-+])? *( #[^\\n]*)?(\\n|$)"),
  (.StringDQ, "^\".*?\""),
  (.StringSQ, "^'.*?'"),
  (.String, "^.*?\(finish)"),
]

func context (var text: String) -> String {
  let endIndex = advance(text.startIndex, 50, text.endIndex)
  text = text.substringToIndex(endIndex)
  text = text.stringByReplacingOccurrencesOfString("\n", withString: "\\n")
  text = text.stringByReplacingOccurrencesOfString("\"", withString: "\\\"")
  return "near \"\(text)\""
}

func tokenize (var text: String) -> (error: String?, tokens: [TokenMatch]?) {
  var matches: [TokenMatch] = []
  var indents = [0]
  var insideFlow = 0
  next:
  while countElements(text) > 0 {
    for tokenPattern in tokenPatterns {
      if let range = text.rangeOfString(tokenPattern.pattern, options: .RegularExpressionSearch) {
        switch tokenPattern.type {

        case .NewLine:
          let match = text.substringWithRange(range)
          let spaces = countElements(match.substringFromIndex(advance(match.startIndex, 1)))
          if insideFlow > 0 || spaces == indents.last! {
            matches.append(TokenMatch(.NewLine, match))
          } else if spaces > indents.last! {
            indents.append(spaces)
            matches.append(TokenMatch(.Indent, match))
          } else {
            while spaces < indents.last! {
              indents.removeLast()
              matches.append(TokenMatch(.Dedent, ""))
            }
            matches.append(TokenMatch(.NewLine, match))
          }

        case .Dash, .QuestionMark:
          let match = text.substringWithRange(range)
          let index = advance(match.startIndex, 1)
          let indent = countElements(match)
          indents.append(indents.last! + indent)
          matches.append(TokenMatch(tokenPattern.type, match.substringToIndex(index)))
          matches.append(TokenMatch(.Indent, match.substringFromIndex(index)))

        case .OpenSB, .OpenCB:
          insideFlow += 1
          matches.append(TokenMatch(tokenPattern.type, text.substringWithRange(range)))

        case .CloseSB, .CloseCB:
          insideFlow -= 1
          matches.append(TokenMatch(tokenPattern.type, text.substringWithRange(range)))

        case .Literal, .Folded:
          matches.append(TokenMatch(tokenPattern.type, text.substringWithRange(range)))
          text = text.substringFromIndex(range.endIndex)
          let lastIndent = indents.last!
          let minIndent = 1 + lastIndent
          let blockPattern = "^( *\\n)*(( {\(minIndent),})[^ ].*(\\n|$)(( *|\\3.*)(\\n|$))*)?"
          if let range = text.rangeOfString(blockPattern, options: .RegularExpressionSearch) {
            var block = text.substringWithRange(range)
            block = block.stringByReplacingOccurrencesOfString(
                "^ {0,\(lastIndent)}", withString: "", options: .RegularExpressionSearch)
            block = block.stringByReplacingOccurrencesOfString(
                "\\n {0,\(lastIndent)}", withString: "\n", options: .RegularExpressionSearch)
            matches.append(TokenMatch(.String, block))
            text = text.substringFromIndex(range.endIndex)
          }
          continue next

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
