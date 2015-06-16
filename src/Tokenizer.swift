import Foundation

enum TokenType: Swift.String, CustomStringConvertible {
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

// printable non-space chars,
// except `:`(3a), `#`(23), `,`(2c), `[`(5b), `]`(5d), `{`(7b), `}`(7d)
let safeIn = "\\x21\\x22\\x24-\\x2b\\x2d-\\x39\\x3b-\\x5a\\x5c\\x5e-\\x7a" +
    "\\x7c\\x7e\\x85\\xa0-\\ud7ff\\ue000-\\ufefe\\uff00\\ufffd" +
    "\\U00010000-\\U0010ffff"
// with flow indicators: `,`, `[`, `]`, `{`, `}`
let safeOut = "\\x2c\\x5b\\x5d\\x7b\\x7d" + safeIn
let plainOutPattern =
    "([\(safeOut)]#|:(?![ \\t]|\(bBreak))|[\(safeOut)]|[ \\t])+"
let plainInPattern =
    "([\(safeIn)]#|:(?![ \\t]|\(bBreak))|[\(safeIn)]|[ \\t]|\(bBreak))+"
let dashPattern = regex("^-([ \\t]+(?!#|\(bBreak))|(?=[ \\t\\n]))")
let finish = "(?= *(,|\\]|\\}|( #.*)?(\(bBreak)|$)))"
let tokenPatterns: [TokenPattern] = [
  (.YamlDirective, regex("^%YAML(?= )")),
  (.DocStart, regex("^---")),
  (.DocEnd, regex("^\\.\\.\\.")),
  (.Comment, regex("^#.*|^\(bBreak) *(#.*)?(?=\(bBreak)|$)")),
  (.Space, regex("^ +")),
  (.NewLine, regex("^\(bBreak) *")),
  (.Dash, dashPattern),
  (.Null, regex("^(null|Null|NULL|~)\(finish)")),
  (.True, regex("^(true|True|TRUE)\(finish)")),
  (.False, regex("^(false|False|FALSE)\(finish)")),
  (.InfinityP, regex("^\\+?\\.(inf|Inf|INF)\(finish)")),
  (.InfinityN, regex("^-\\.(inf|Inf|INF)\(finish)")),
  (.NaN, regex("^\\.(nan|NaN|NAN)\(finish)")),
  (.Int, regex("^[-+]?[0-9]+\(finish)")),
  (.IntOct, regex("^0o[0-7]+\(finish)")),
  (.IntHex, regex("^0x[0-9a-fA-F]+\(finish)")),
  (.IntSex, regex("^[0-9]{2}(:[0-9]{2})+\(finish)")),
  (.Double, regex("^[-+]?(\\.[0-9]+|[0-9]+(\\.[0-9]*)?)([eE][-+]?[0-9]+)?\(finish)")),
  (.Anchor, regex("^&\\w+")),
  (.Alias, regex("^\\*\\w+")),
  (.Comma, regex("^,")),
  (.OpenSB, regex("^\\[")),
  (.CloseSB, regex("^\\]")),
  (.OpenCB, regex("^\\{")),
  (.CloseCB, regex("^\\}")),
  (.QuestionMark, regex("^\\?( +|(?=\(bBreak)))")),
  (.ColonFO, regex("^:(?!:)")),
  (.ColonFI, regex("^:(?!:)")),
  (.Literal, regex("^\\|.*")),
  (.Folded, regex("^>.*")),
  (.Reserved, regex("^[@`]")),
  (.StringDQ, regex("^\"([^\\\\\"]|\\\\(.|\(bBreak)))*\"")),
  (.StringSQ, regex("^'([^']|'')*'")),
  (.StringFO, regex("^\(plainOutPattern)(?=:([ \\t]|\(bBreak))|\(bBreak)|$)")),
  (.StringFI, regex("^\(plainInPattern)")),
]

func escapeErrorContext (text: String) -> String {
  let endIndex = advance(text.startIndex, 50, text.endIndex)
  let escaped = text.substringToIndex(endIndex)
      |> replace(regex("\\r"), template: "\\\\r")
      |> replace(regex("\\n"), template: "\\\\n")
      |> replace(regex("\""), template: "\\\\\"")
  return "near \"\(escaped)\""
}

func tokenize (var text: String) -> Result<[TokenMatch]> {
  var matchList: [TokenMatch] = []
  var indents = [0]
  var insideFlow = 0
  next:
  while text.endIndex > text.startIndex {
    for tokenPattern in tokenPatterns {
      let range = matchRange(text, regex: tokenPattern.pattern)
      if range.location != NSNotFound {
        let rangeEnd = range.location + range.length
        switch tokenPattern.type {

        case .NewLine:
          let match = text |> substringWithRange(range)
          let lastIndent = indents.last ?? 0
          let rest = match.substringFromIndex(match.startIndex.successor())
          let spaces = rest.characters.count
          let nestedBlockSequence =
                matches(text |> substringFromIndex(rangeEnd), regex: dashPattern)
          if spaces == lastIndent {
            matchList.append(TokenMatch(.NewLine, match))
          } else if spaces > lastIndent {
            if insideFlow == 0 {
              if matchList.last != nil &&
                  matchList[matchList.endIndex - 1].type == .Indent {
                indents[indents.endIndex - 1] = spaces
                matchList[matchList.endIndex - 1] = TokenMatch(.Indent, match)
              } else {
                indents.append(spaces)
                matchList.append(TokenMatch(.Indent, match))
              }
            }
          } else if nestedBlockSequence && spaces == lastIndent - 1 {
            matchList.append(TokenMatch(.NewLine, match))
          } else {
            while nestedBlockSequence && spaces < (indents.last ?? 0) - 1
                || !nestedBlockSequence && spaces < indents.last {
              indents.removeLast()
              matchList.append(TokenMatch(.Dedent, ""))
            }
            matchList.append(TokenMatch(.NewLine, match))
          }

        case .Dash, .QuestionMark:
          let match = text |> substringWithRange(range)
          let index = match.startIndex.successor()
          let indent = match.characters.count
          indents.append((indents.last ?? 0) + indent)
          matchList.append(
              TokenMatch(tokenPattern.type, match.substringToIndex(index)))
          matchList.append(TokenMatch(.Indent, match.substringFromIndex(index)))

        case .ColonFO:
          if insideFlow > 0 {
            continue
          }
          fallthrough

        case .ColonFI:
          let match = text |> substringWithRange(range)
          matchList.append(TokenMatch(.Colon, match))
          if insideFlow == 0 {
            indents.append((indents.last ?? 0) + 1)
            matchList.append(TokenMatch(.Indent, ""))
          }

        case .OpenSB, .OpenCB:
          insideFlow += 1
          matchList.append(TokenMatch(tokenPattern.type, text |> substringWithRange(range)))

        case .CloseSB, .CloseCB:
          insideFlow -= 1
          matchList.append(TokenMatch(tokenPattern.type, text |> substringWithRange(range)))

        case .Literal, .Folded:
          matchList.append(TokenMatch(tokenPattern.type, text |> substringWithRange(range)))
          text = text |> substringFromIndex(rangeEnd)
          let lastIndent = indents.last ?? 0
          let minIndent = 1 + lastIndent
          let blockPattern = regex(("^(\(bBreak) *)*(\(bBreak)" +
              "( {\(minIndent),})[^ ].*(\(bBreak)( *|\\3.*))*)(?=\(bBreak)|$)"))
          let (lead, rest) = text |> splitLead(blockPattern)
          text = rest
          let block = (lead
              |> replace(regex("^\(bBreak)"), template: "")
              |> replace(regex("^ {0,\(lastIndent)}"), template: "")
              |> replace(regex("\(bBreak) {0,\(lastIndent)}"), template: "\n")
            ) + (matches(text, regex: regex("^\(bBreak)")) && lead.endIndex > lead.startIndex
              ? "\n" : "")
          matchList.append(TokenMatch(.String, block))
          continue next

        case .StringFO:
          if insideFlow > 0 {
            continue
          }
          let indent = (indents.last ?? 0)
          let blockPattern = regex(("^\(bBreak)( *| {\(indent),}" +
              "\(plainOutPattern))(?=\(bBreak)|$)"))
          var block = text
                |> substringWithRange(range)
                |> replace(regex("^[ \\t]+|[ \\t]+$"), template: "")
          text = text |> substringFromIndex(rangeEnd)
          while true {
            let range = matchRange(text, regex: blockPattern)
            if range.location == NSNotFound {
              break
            }
            let s = text |> substringWithRange(range)
            block += "\n" +
                replace(regex("^\(bBreak)[ \\t]*|[ \\t]+$"), template: "")(string: s)
            text = text |> substringFromIndex(range.location + range.length)
          }
          matchList.append(TokenMatch(.String, block))
          continue next

        case .StringFI:
          let match = text
                |> substringWithRange(range)
                |> replace(regex("^[ \\t]|[ \\t]$"), template: "")
          matchList.append(TokenMatch(.String, match))

        case .Reserved:
          return fail(escapeErrorContext(text))

        default:
          matchList.append(TokenMatch(tokenPattern.type, text |> substringWithRange(range)))
        }
        text = text |> substringFromIndex(rangeEnd)
        continue next
      }
    }
    return fail(escapeErrorContext(text))
  }
  while indents.count > 1 {
    indents.removeLast()
    matchList.append((.Dedent, ""))
  }
  matchList.append((.End, ""))
  return lift(matchList)
}
