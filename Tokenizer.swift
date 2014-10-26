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
  case ColonFO = ":-flow-out"
  case ColonFI = ":-flow-in"
  case Colon = ":"
  case Literal = "|"
  case Folded = ">"
  case StringDQ = "string-dq"
  case StringSQ = "string-sq"
  case StringFI = "string-flow-in"
  case StringFO = "string-flow-out"
  case String = "string"
  case End = "end"

  var description: Swift.String {
    return self.rawValue
  }
}

typealias TokenPattern = (type: TokenType, pattern: String)
typealias TokenMatch = (type: TokenType, match: String)

// printable non-space chars, except `:`(3a), `#`(23), `,`(2c), `[`(5b), `]`(5d), `{`(7b), `}`(7d)
let safeIn = "\\x21\\x22\\x24-\\x2b\\x2d-\\x39\\x3b-\\x5a\\x5c\\x5e-\\x7a\\x7c\\x7e\\x85" +
    "\\xa0-\\ud7ff\\ue000-\\ufefe\\uff00\\ufffd\\U00010000-\\U0010ffff"
// with flow indicators: `,`, `[`, `]`, `{`, `}`
let safeOut = "\\x2c\\x5b\\x5d\\x7b\\x7d" + safeIn
let plainOutPattern = "([\(safeOut)]#|:[\(safeOut)]|[\(safeOut)]|[ \\t])+"
let plainInPattern = "([\(safeIn)]#|:[\(safeIn)]|[\(safeIn)]|[ \\t\\n])+"
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
  (.QuestionMark, "^\\?( +|(?=\\n))"),
  (.ColonFO, "^:(?!\(safeOut))"),
  (.ColonFI, "^:(?!\(safeIn))"),
  (.Literal, "^\\|([-+]|[1-9]|[-+][1-9]|[1-9][-+])? *( #[^\\n]*)?(\\n|$)"),
  (.Folded, "^>([-+]|[1-9]|[-+][1-9]|[1-9][-+])? *( #[^\\n]*)?(\\n|$)"),
  (.StringDQ, "^\"([^\\\\\"]|\\\\(.|\\n))*\""),
  (.StringSQ, "^'([^']|'')*'"),
  (.StringFO, "^\(plainOutPattern)(?=:|\\n|$)"),
  (.StringFI, "^\(plainInPattern)"),
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
          if insideFlow > 0 || spaces == (indents.last ?? 0) {
            matches.append(TokenMatch(.NewLine, match))
          } else if spaces > (indents.last ?? 0) {
            indents.append(spaces)
            matches.append(TokenMatch(.Indent, match))
          } else {
            while spaces < (indents.last ?? 0) {
              indents.removeLast()
              matches.append(TokenMatch(.Dedent, ""))
            }
            matches.append(TokenMatch(.NewLine, match))
          }

        case .Dash, .QuestionMark:
          let match = text.substringWithRange(range)
          let index = advance(match.startIndex, 1)
          let indent = countElements(match)
          indents.append((indents.last ?? 0) + indent)
          matches.append(TokenMatch(tokenPattern.type, match.substringToIndex(index)))
          matches.append(TokenMatch(.Indent, match.substringFromIndex(index)))

        case .ColonFO, .ColonFI:
          let match = text.substringWithRange(range)
          matches.append(TokenMatch(.Colon, match))

        case .OpenSB, .OpenCB:
          insideFlow += 1
          matches.append(TokenMatch(tokenPattern.type, text.substringWithRange(range)))

        case .CloseSB, .CloseCB:
          insideFlow -= 1
          matches.append(TokenMatch(tokenPattern.type, text.substringWithRange(range)))

        case .Literal, .Folded:
          matches.append(TokenMatch(tokenPattern.type, text.substringWithRange(range)))
          text = text.substringFromIndex(range.endIndex)
          let lastIndent = indents.last ?? 0
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

        case .StringFO:
          if insideFlow > 0 {
            continue
          }
          let indent = (indents.last ?? 0) + 1
          let blockPattern = "^\\n( *| {\(indent),}\(plainOutPattern))(?=\\n|$)"
          var block = text.substringWithRange(range)
          text = text.substringFromIndex(range.endIndex)
          while let range = text.rangeOfString(blockPattern, options: .RegularExpressionSearch) {
            block += text.substringWithRange(range)
            text = text.substringFromIndex(range.endIndex)
          }
          matches.append(TokenMatch(.String, block))
          continue next

        case .StringFI:
          let match = text.substringWithRange(range).stringByReplacingOccurrencesOfString(
              "^[ \\t]|[ \\t]$", withString: "", options: .RegularExpressionSearch)
          matches.append(TokenMatch(.String, match))

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
