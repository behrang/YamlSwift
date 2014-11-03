import Foundation

enum TokenType: Swift.String, Printable {
  case YamlDirective = "%YAML"
  case DocStart = "doc-start"
  case DocEnd = "doc-end"
  case Comment = "comment"
  case Space = "space"
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
  case Reserved = "reserved"
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

typealias TokenPattern = (type: TokenType, pattern: NSRegularExpression)
typealias TokenMatch = (type: TokenType, match: String)

let bBreak = "(?:\\r\\n|\\r|\\n)"

// printable non-space chars, except `:`(3a), `#`(23), `,`(2c), `[`(5b), `]`(5d), `{`(7b), `}`(7d)
let safeIn = "\\x21\\x22\\x24-\\x2b\\x2d-\\x39\\x3b-\\x5a\\x5c\\x5e-\\x7a\\x7c\\x7e\\x85" +
    "\\xa0-\\ud7ff\\ue000-\\ufefe\\uff00\\ufffd\\U00010000-\\U0010ffff"
// with flow indicators: `,`, `[`, `]`, `{`, `}`
let safeOut = "\\x2c\\x5b\\x5d\\x7b\\x7d" + safeIn
let plainOutPattern = "([\(safeOut)]#|:(?![ \\t]|\(bBreak))|[\(safeOut)]|[ \\t])+"
let plainInPattern = "([\(safeIn)]#|:(?![ \\t]|\(bBreak))|[\(safeIn)]|[ \\t]|\(bBreak))+"
let dashPattern = /"^-([ \\t]+(?!#|\(bBreak))|(?=[ \\t\\n]))"
let finish = "(?= *(,|\\]|\\}|( #.*)?(\(bBreak)|$)))"
let tokenPatterns: [TokenPattern] = [
  (.YamlDirective, /"^%YAML(?= )"),
  (.DocStart, /"^---"),
  (.DocEnd, /"^\\.\\.\\."),
  (.Comment, /"^#.*|^\(bBreak) *(#.*)?(?=\(bBreak)|$)"),
  (.Space, /"^ +"),
  (.NewLine, /"^\(bBreak) *"),
  (.Dash, dashPattern),
  (.Null, /"^(null|Null|NULL|~)\(finish)"),
  (.True, /"^(true|True|TRUE)\(finish)"),
  (.False, /"^(false|False|FALSE)\(finish)"),
  (.InfinityP, /"^\\+?\\.(inf|Inf|INF)\(finish)"),
  (.InfinityN, /"^-\\.(inf|Inf|INF)\(finish)"),
  (.NaN, /"^\\.(nan|NaN|NAN)\(finish)"),
  (.Int, /"^[-+]?[0-9]+\(finish)"),
  (.IntOct, /"^0o[0-7]+\(finish)"),
  (.IntHex, /"^0x[0-9a-fA-F]+\(finish)"),
  (.IntSex, /"^[0-9]{2}(:[0-9]{2})+\(finish)"),
  (.Double, /"^[-+]?(\\.[0-9]+|[0-9]+(\\.[0-9]*)?)([eE][-+]?[0-9]+)?\(finish)"),
  (.Anchor, /"^&\\w+"),
  (.Alias, /"^\\*\\w+"),
  (.Comma, /"^,"),
  (.OpenSB, /"^\\["),
  (.CloseSB, /"^\\]"),
  (.OpenCB, /"^\\{"),
  (.CloseCB, /"^\\}"),
  (.QuestionMark, /"^\\?( +|(?=\(bBreak)))"),
  (.ColonFO, /"^:(?!:)"),
  (.ColonFI, /"^:(?!:)"),
  (.Literal, /"^\\|([-+]|[1-9]|[-+][1-9]|[1-9][-+])? *( #.*)?(?=\(bBreak)|$)"),
  (.Folded, /"^>([-+]|[1-9]|[-+][1-9]|[1-9][-+])? *( #.*)?(?=\(bBreak)|$)"),
  (.Reserved, /"^[@`]"),
  (.StringDQ, /"^\"([^\\\\\"]|\\\\(.|\(bBreak)))*\""),
  (.StringSQ, /"^'([^']|'')*'"),
  (.StringFO, /"^\(plainOutPattern)(?=:([ \\t]|\(bBreak))|\(bBreak)|$)"),
  (.StringFI, /"^\(plainInPattern)"),
]

func context (var text: String) -> String {
  let endIndex = advance(text.startIndex, 50, text.endIndex)
  text = text.substringToIndex(endIndex)
  text = text.replace(/"\\r", "\\\\r")
  text = text.replace(/"\\n", "\\\\n")
  text = text.replace(/"\"", "\\\\\"")
  return "near \"\(text)\""
}

func tokenize (var text: String) -> (error: String?, tokens: [TokenMatch]?) {
  var matches: [TokenMatch] = []
  var indents = [0]
  var insideFlow = 0
  next:
  while text.endIndex > text.startIndex {
    for tokenPattern in tokenPatterns {
      if let range = text ~< tokenPattern.pattern {
        switch tokenPattern.type {

        case .NewLine:
          let match = text[range]
          let lastIndent = indents.last ?? 0
          let spaces = countElements(match.substringFromIndex(match.startIndex.successor()))
          let nestedBlockSequence = text.substringFromIndex(range.endIndex) ~ dashPattern
          if spaces == lastIndent {
            matches.append(TokenMatch(.NewLine, match))
          } else if spaces > lastIndent {
            if insideFlow == 0 {
              if matches.last != nil && matches[matches.endIndex - 1].type == .Indent {
                indents[indents.endIndex - 1] = spaces
                matches[matches.endIndex - 1] = TokenMatch(.Indent, match)
              } else {
                indents.append(spaces)
                matches.append(TokenMatch(.Indent, match))
              }
            }
          } else if nestedBlockSequence && spaces == lastIndent - 1 {
            matches.append(TokenMatch(.NewLine, match))
          } else {
            while nestedBlockSequence && spaces < (indents.last ?? 0) - 1
                || !nestedBlockSequence && spaces < indents.last {
              indents.removeLast()
              matches.append(TokenMatch(.Dedent, ""))
            }
            matches.append(TokenMatch(.NewLine, match))
          }

        case .Dash, .QuestionMark:
          let match = text[range]
          let index = match.startIndex.successor()
          let indent = countElements(match)
          indents.append((indents.last ?? 0) + indent)
          matches.append(TokenMatch(tokenPattern.type, match.substringToIndex(index)))
          matches.append(TokenMatch(.Indent, match.substringFromIndex(index)))

        case .ColonFO:
          if insideFlow > 0 {
            continue
          }
          fallthrough

        case .ColonFI:
          let match = text[range]
          matches.append(TokenMatch(.Colon, match))
          if insideFlow == 0 {
            indents.append((indents.last ?? 0) + 1)
            matches.append(TokenMatch(.Indent, ""))
          }

        case .OpenSB, .OpenCB:
          insideFlow += 1
          matches.append(TokenMatch(tokenPattern.type, text[range]))

        case .CloseSB, .CloseCB:
          insideFlow -= 1
          matches.append(TokenMatch(tokenPattern.type, text[range]))

        case .Literal, .Folded:
          matches.append(TokenMatch(tokenPattern.type, text[range]))
          text = text.substringFromIndex(range.endIndex)
          let lastIndent = indents.last ?? 0
          let minIndent = 1 + lastIndent
          let blockPattern =
              /"^(\(bBreak) *)*(\(bBreak)( {\(minIndent),})[^ ].*(\(bBreak)( *|\\3.*))*)(?=\(bBreak)|$)"
          var block = ""
          if let range = text ~< blockPattern {
            block = text[range]
            block = block.replace(/"^\(bBreak)", "")
            block = block.replace(/"^ {0,\(lastIndent)}", "")
            block = block.replace(/"\(bBreak) {0,\(lastIndent)}", "\n")
            text = text.substringFromIndex(range.endIndex)
            if text ~ /"^\(bBreak)" {
              block += "\n"
            }
          }
          matches.append(TokenMatch(.String, block))
          continue next

        case .StringFO:
          if insideFlow > 0 {
            continue
          }
          let indent = (indents.last ?? 0)
          let blockPattern = /"^\(bBreak)( *| {\(indent),}\(plainOutPattern))(?=\(bBreak)|$)"
          var block = text[range].replace(/"^[ \\t]+|[ \\t]+$", "")
          text = text.substringFromIndex(range.endIndex)
          while let range = text ~< blockPattern {
            block += "\n" + text[range].replace(/"^\(bBreak)[ \\t]*|[ \\t]+$", "")
            text = text.substringFromIndex(range.endIndex)
          }
          matches.append(TokenMatch(.String, block))
          continue next

        case .StringFI:
          let match = text[range].replace(/"^[ \\t]|[ \\t]$", "")
          matches.append(TokenMatch(.String, match))

        case .Reserved:
          return (context(text), nil)

        default:
          matches.append(TokenMatch(tokenPattern.type, text[range]))
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
