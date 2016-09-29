import Foundation

enum TokenType: Swift.String {
  case yamlDirective = "%YAML"
  case docStart = "doc-start"
  case docend = "doc-end"
  case comment = "comment"
  case space = "space"
  case newLine = "newline"
  case indent = "indent"
  case dedent = "dedent"
  case null = "null"
  case _true = "true"
  case _false = "false"
  case infinityP = "+infinity"
  case infinityN = "-infinity"
  case nan = "nan"
  case double = "double"
  case int = "int"
  case intOct = "int-oct"
  case intHex = "int-hex"
  case intSex = "int-sex"
  case anchor = "&"
  case alias = "*"
  case comma = ","
  case openSB = "["
  case closeSB = "]"
  case dash = "-"
  case openCB = "{"
  case closeCB = "}"
  case key = "key"
  case keyDQ = "key-dq"
  case keySQ = "key-sq"
  case questionMark = "?"
  case colonFO = ":-flow-out"
  case colonFI = ":-flow-in"
  case colon = ":"
  case literal = "|"
  case folded = ">"
  case reserved = "reserved"
  case stringDQ = "string-dq"
  case stringSQ = "string-sq"
  case stringFI = "string-flow-in"
  case stringFO = "string-flow-out"
  case string = "string"
  case end = "end"
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
  (.yamlDirective, regex("^%YAML(?= )")),
  (.docStart, regex("^---")),
  (.docend, regex("^\\.\\.\\.")),
  (.comment, regex("^#.*|^\(bBreak) *(#.*)?(?=\(bBreak)|$)")),
  (.space, regex("^ +")),
  (.newLine, regex("^\(bBreak) *")),
  (.dash, dashPattern!),
  (.null, regex("^(null|Null|NULL|~)\(finish)")),
  (._true, regex("^(true|True|TRUE)\(finish)")),
  (._false, regex("^(false|False|FALSE)\(finish)")),
  (.infinityP, regex("^\\+?\\.(inf|Inf|INF)\(finish)")),
  (.infinityN, regex("^-\\.(inf|Inf|INF)\(finish)")),
  (.nan, regex("^\\.(nan|NaN|NAN)\(finish)")),
  (.int, regex("^[-+]?[0-9]+\(finish)")),
  (.intOct, regex("^0o[0-7]+\(finish)")),
  (.intHex, regex("^0x[0-9a-fA-F]+\(finish)")),
  (.intSex, regex("^[0-9]{2}(:[0-9]{2})+\(finish)")),
  (.double, regex("^[-+]?(\\.[0-9]+|[0-9]+(\\.[0-9]*)?)([eE][-+]?[0-9]+)?\(finish)")),
  (.anchor, regex("^&\\w+")),
  (.alias, regex("^\\*\\w+")),
  (.comma, regex("^,")),
  (.openSB, regex("^\\[")),
  (.closeSB, regex("^\\]")),
  (.openCB, regex("^\\{")),
  (.closeCB, regex("^\\}")),
  (.questionMark, regex("^\\?( +|(?=\(bBreak)))")),
  (.colonFO, regex("^:(?!:)")),
  (.colonFI, regex("^:(?!:)")),
  (.literal, regex("^\\|.*")),
  (.folded, regex("^>.*")),
  (.reserved, regex("^[@`]")),
  (.stringDQ, regex("^\"([^\\\\\"]|\\\\(.|\(bBreak)))*\"")),
  (.stringSQ, regex("^'([^']|'')*'")),
  (.stringFO, regex("^\(plainOutPattern)(?=:([ \\t]|\(bBreak))|\(bBreak)|$)")),
  (.stringFI, regex("^\(plainInPattern)")),
]

func escapeErrorContext (_ text: String) -> String {
  let endIndex = text.index(text.startIndex, offsetBy: 50, limitedBy: text.endIndex) ?? text.endIndex
  let escaped = text.substring(to: endIndex)
      |> replace(regex("\\r"), template: "\\\\r")
      |> replace(regex("\\n"), template: "\\\\n")
      |> replace(regex("\""), template: "\\\\\"")
  return "near \"\(escaped)\""
}

func tokenize (_ text: String) -> Result<[TokenMatch]> {
  var text = text
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

        case .newLine:
          let match = text |> substringWithRange(range)
          let lastIndent = indents.last ?? 0
          let rest = match.substring(from: match.index(after: match.startIndex))
          let spaces = rest.characters.count
          let nestedBlockSequence =
                matches(text |> substringFromIndex(rangeEnd), regex: dashPattern!)
          if spaces == lastIndent {
            matchList.append(TokenMatch(.newLine, match))
          } else if spaces > lastIndent {
            if insideFlow == 0 {
              if matchList.last != nil &&
                  matchList[matchList.endIndex - 1].type == .indent {
                indents[indents.endIndex - 1] = spaces
                matchList[matchList.endIndex - 1] = TokenMatch(.indent, match)
              } else {
                indents.append(spaces)
                matchList.append(TokenMatch(.indent, match))
              }
            }
          } else if nestedBlockSequence && spaces == lastIndent - 1 {
            matchList.append(TokenMatch(.newLine, match))
          } else {
            while nestedBlockSequence && spaces < (indents.last ?? 0) - 1
                || !nestedBlockSequence && spaces < indents.last ?? 0 {
              indents.removeLast()
              matchList.append(TokenMatch(.dedent, ""))
            }
            matchList.append(TokenMatch(.newLine, match))
          }

        case .dash, .questionMark:
          let match = text |> substringWithRange(range)
          let index = match.index(after: match.startIndex)
          let indent = match.characters.count
          indents.append((indents.last ?? 0) + indent)
          matchList.append(
            TokenMatch(tokenPattern.type, match.substring(to: index)))
          matchList.append(TokenMatch(.indent, match.substring(from: index)))

        case .colonFO:
          if insideFlow > 0 {
            continue
          }
          fallthrough

        case .colonFI:
          let match = text |> substringWithRange(range)
          matchList.append(TokenMatch(.colon, match))
          if insideFlow == 0 {
            indents.append((indents.last ?? 0) + 1)
            matchList.append(TokenMatch(.indent, ""))
          }

        case .openSB, .openCB:
          insideFlow += 1
          matchList.append(TokenMatch(tokenPattern.type, text |> substringWithRange(range)))

        case .closeSB, .closeCB:
          insideFlow -= 1
          matchList.append(TokenMatch(tokenPattern.type, text |> substringWithRange(range)))

        case .literal, .folded:
          matchList.append(TokenMatch(tokenPattern.type, text |> substringWithRange(range)))
          text = text |> substringFromIndex(rangeEnd)
          let lastIndent = indents.last ?? 0
          let minIndent = 1 + lastIndent
          let blockPattern = regex(("^(\(bBreak) *)*(\(bBreak)" +
              "( {\(minIndent),})[^ ].*(\(bBreak)( *|\\3.*))*)(?=\(bBreak)|$)"))
          let (lead, rest) = text |> splitLead(blockPattern!)
          text = rest
          let block = (lead
              |> replace(regex("^\(bBreak)"), template: "")
              |> replace(regex("^ {0,\(lastIndent)}"), template: "")
              |> replace(regex("\(bBreak) {0,\(lastIndent)}"), template: "\n")
            ) + (matches(text, regex: regex("^\(bBreak)")) && lead.endIndex > lead.startIndex
              ? "\n" : "")
          matchList.append(TokenMatch(.string, block))
          continue next

        case .stringFO:
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
            let range = matchRange(text, regex: blockPattern!)
            if range.location == NSNotFound {
              break
            }
            let s = text |> substringWithRange(range)
            block += "\n" +
                replace(regex("^\(bBreak)[ \\t]*|[ \\t]+$"), template: "")(s)
            text = text |> substringFromIndex(range.location + range.length)
          }
          matchList.append(TokenMatch(.string, block))
          continue next

        case .stringFI:
          let match = text
                |> substringWithRange(range)
                |> replace(regex("^[ \\t]|[ \\t]$"), template: "")
          matchList.append(TokenMatch(.string, match))

        case .reserved:
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
    matchList.append((.dedent, ""))
  }
  matchList.append((.end, ""))
  return lift(matchList)
}
