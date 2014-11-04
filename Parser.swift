import Foundation

class Parser {
  let tokens: [TokenMatch]
  var index: Int = 0
  var aliases: [String: Yaml] = [:]

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

  func buildContext (count: Int = 50) -> String {
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
    while contains([.Comment, .Space, .NewLine], peek().type) {
      advance()
    }
  }

  func ignoreWhiteSpace () {
    while contains([.Comment, .Space, .NewLine, .Indent, .Dedent], peek().type) {
      advance()
    }
  }

  func ignoreDocEnd () {
    while contains([.Comment, .Space, .NewLine, .DocEnd], peek().type) {
      advance()
    }
  }

  func parseHeader () -> String? {
    aliases = [:]
    var readYaml = false
    while true {
      switch peek().type {
      case .Comment, .Space, .NewLine:
        advance()
      case .YamlDirective:
        if readYaml {
          return expect(.DocStart, message: "expected ---")
        }
        readYaml = true
        advance()
        expect(.Space, message: "expected space")
        let version = advance().match
        if version != "1.1" && version != "1.2" {
          return "invalid yaml version, " + context(buildContext())
        }
      case .DocStart:
        advance()
        return nil
      default:
        if readYaml {
          return expect(.DocStart, message: "expected ---")
        } else {
          return nil
        }
      }
    }
  }

  func parse () -> Yaml {
    switch peek().type {

    case .Comment, .Space, .NewLine:
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
      let m = advance().match.replace(/"0o", "")
      return .Int(parseInt(m, radix: 8)) // will throw runtime error if overflows

    case .IntHex:
      let m = advance().match.replace(/"0x", "")
      return .Int(parseInt(m, radix: 16)) // will throw runtime error if overflows

    case .IntSex:
      let m = advance().match
      return .Int(parseInt(m, radix: 60))

    case .InfinityP:
      advance()
      return .Double(Double.infinity)

    case .InfinityN:
      advance()
      return .Double(-Double.infinity)

    case .NaN:
      advance()
      return .Double(Double.NaN)

    case .Double:
      let m = advance().match as NSString
      return .Double(m.doubleValue)

    case .Dash:
      return parseBlockSeq()

    case .OpenSB:
      return parseFlowSeq()

    case .OpenCB:
      return parseFlowMap()

    case .QuestionMark:
      return parseBlockMap()

    case .StringDQ, .StringSQ, .String:
      return parseBlockMapOrString()

    case .Literal:
      return parseLiteral()

    case .Folded:
      let block = parseLiteral()
      if block.string == nil {
        return block
      }
      return .String(foldBlock(block.string ?? ""))

    case .Indent:
      accept(.Indent)
      let result = parse()
      if let error = expect(.Dedent, message: "expected dedent") {
        return .Invalid(error)
      }
      return result

    case .Anchor:
      let m = advance().match
      let name = m.substringFromIndex(m.startIndex.successor())
      let value = parse()
      aliases[name] = value
      return value

    case .Alias:
      let m = advance().match
      let name = m.substringFromIndex(m.startIndex.successor())
      if aliases[name] == nil {
        return .Invalid("unknown alias \(name), \(context(buildContext()))")
      }
      return aliases[name] ?? .Null

    case .End:
      return .Null

    default:
      return .Invalid("unexpected type \(peek().type), \(context(buildContext()))")

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
    return .Array(seq)
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
    return .Array(seq)
  }

  func parseFlowMap () -> Yaml {
    var map: [Yaml: Yaml] = [:]
    accept(.OpenCB)
    while !accept(.CloseCB) {
      ignoreWhiteSpace()
      if map.count > 0 {
        if let error = expect(.Comma, message: "expected comma") {
          return .Invalid(error)
        }
      }
      ignoreWhiteSpace()
      var k: Yaml
      switch peek().type {
      case .String, .StringDQ, .StringSQ:
        k = parseString()
      default:
        return .Invalid("expected key, \(context(buildContext()))")
      }
      if map[k] != nil {
        return .Invalid("duplicate key \(k), \(context(buildContext()))")
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
    return .Dictionary(map)
  }

  func parseBlockMap () -> Yaml {
    var map: [Yaml: Yaml] = [:]
    while contains([.String, .StringDQ, .StringSQ, .QuestionMark], peek().type) {
      var k: Yaml
      switch peek().type {
      case .QuestionMark:
        advance()
        k = parse()
        switch k {
        case .Invalid:
          return k
        default:
          break
        }
        if map[k] != nil {
          return .Invalid("duplicate key \(k), \(context(buildContext()))")
        }
        ignoreSpace()
        if peek().type != .Colon {
          map.updateValue(.Null, forKey: k)
          continue
        }
      case .String, .StringDQ, .StringSQ:
        k = parseString()
      default:
        return .Invalid("expected key, \(context(buildContext()))")
      }
      if map[k] != nil {
        return .Invalid("duplicate key \(k), \(context(buildContext()))")
      }
      ignoreSpace()
      if let error = expect(.Colon, message: "expected colon") {
        return .Invalid(error)
      }
      ignoreSpace()
      accept(.Indent)
      ignoreSpace()
      if accept(.Dedent) {
        map.updateValue(.Null, forKey: k)
      } else {
        let v = parse()
        switch v {
        case .Invalid:
          return v
        default:
          map.updateValue(v, forKey: k)
        }
        ignoreSpace()
        if let error = expect(.Dedent, message: "expected dedent") {
          return .Invalid(error)
        }
      }
      ignoreSpace()
    }
    return .Dictionary(map)
  }

  func parseString () -> Yaml {
    switch peek().type {
    case .String:
      let m = normalizeBreaks(advance().match)
      return .String(foldFlow(m.replace(/"^[ \\t\\n]+|[ \\t\\n]+$", "")))
    case .StringDQ:
      let m = unwrapQuotedString(normalizeBreaks(advance().match))
      return .String(unescapeDoubleQuotes(foldFlow(m)))
    case .StringSQ:
      let m = unwrapQuotedString(normalizeBreaks(advance().match))
      return .String(unescapeSingleQuotes(foldFlow(m)))
    default:
      return .Invalid("expected string, \(context(buildContext()))")
    }
  }

  func parseBlockMapOrString () -> Yaml {
    let match = peek().match
    if tokens[index + 1].type != .Colon || match ~ /"\n" {
      return parseString()
    } else {
      return parseBlockMap()
    }
  }

  func foldBlock (var block: String) -> String {
    var trail = ""
    if let range = block ~< /"\\n*$" {
      trail = block.substringFromIndex(range.startIndex)
      block = block.substringToIndex(range.startIndex)
    }
    block = block.replace("m"/"^([^ \\t\\n].*)\\n(?=[^ \\t\\n])", "$1 ")
    block = block.replace("m"/"^([^ \\t\\n].*)\\n(\\n+)(?![ \\t])", "$1$2")
    return block + trail
  }

  func foldFlow (var flow: String) -> String {
    var lead = ""
    var trail = ""
    if let range = flow ~< /"^[ \\t]+" {
      lead = flow.substringToIndex(range.endIndex)
      flow = flow.substringFromIndex(range.endIndex)
    }
    if let range = flow ~< /"[ \\t]+$" {
      trail = flow.substringFromIndex(range.startIndex)
      flow = flow.substringToIndex(range.startIndex)
    }
    flow = flow.replace("m"/"^[ \\t]+|[ \\t]+$|\\\\\\n", "")
    flow = flow.replace(/"(^|.)\\n(?=.|$)", "$1 ")
    flow = flow.replace(/"(.)\\n(\\n+)", "$1$2")
    return lead + flow + trail
  }

  func parseLiteral () -> Yaml {
    let literal = advance().match
    var chomp = 0
    if literal ~ /"-" {
      chomp = -1
    } else if literal ~ /"\\+" {
      chomp = 1
    }
    var indent = 0
    if let range = literal ~< /"[1-9]" {
      indent = parseInt(literal[range], radix: 10)
    }
    let token = advance()
    if token.type != .String {
      return .Invalid("expected scalar block, \(context(buildContext()))")
    }
    var block = normalizeBreaks(token.match)
    var foundIndent = 0
    if let range = block ~< /"^( *\\n)* {1,}(?! |\\n|$)" {
      let indentText = block[range]
      foundIndent = countElements(indentText.replace(/"^( *\\n)*", ""))
      let invalidPattern = /"^( {0,\(foundIndent)}\\n)* {\(foundIndent + 1),}"
      if block ~ invalidPattern {
        return .Invalid(
            "leading all-space line must not have to many spaces, \(context(buildContext()))")
      }
    }
    if indent > 0 && foundIndent < indent {
      return .Invalid(
          "less indented block scalar than the indicated level, \(context(buildContext()))")
    } else if indent == 0 {
      indent = foundIndent
    }
    block = block.replace(/"^ {0,\(indent)}", "")
    block = block.replace(/"\\n {0,\(indent)}", "\n")

    if chomp == -1 {
      block = block.replace(/"(\\n *)*$", "")
    } else if chomp == 0 {
      block = block.replace(/"(?=[^ ])(\\n *)*$", "\n")
    }
    return .String(block)
  }
}

func parseInt (s: String, #radix: Int) -> Int {
  if radix == 60 {
    return reduce(s.componentsSeparatedByString(":").map {
      $0.toInt() ?? 0
    }, 0, {$0 * radix + $1})
  } else {
    return reduce(lazy(s.unicodeScalars).map {
      c in
      switch c {
      case "0"..."9":
        return c.value - UnicodeScalar("0").value
      case "a"..."z":
        return c.value - UnicodeScalar("a").value + 10
      case "A"..."Z":
        return c.value - UnicodeScalar("A").value + 10
      default:
        fatalError("invalid digit")
      }
    }, 0, {$0 * radix + $1})
  }
}

func normalizeBreaks (s: String) -> String {
  return s.replace(/"\\r\\n|\\r", "\n")
}

func unwrapQuotedString (s: String) -> String {
  return s[s.startIndex.successor()..<s.endIndex.predecessor()]
}

func unescapeSingleQuotes (s: String) -> String {
  return s.replace(/"''", "'")
}

func unescapeDoubleQuotes (input: String) -> String {
  var result = input.replace(/"\\\\([0abtnvfre \"\\/N_LP])") { $ in
    escapeCharacters[$[1]] ?? ""
  }
  result = result.replace(/"\\\\x([0-9A-Fa-f]{2})") { $ in
    String(UnicodeScalar(parseInt($[1], radix: 16)))
  }
  result = result.replace(/"\\\\u([0-9A-Fa-f]{4})") { $ in
    String(UnicodeScalar(parseInt($[1], radix: 16)))
  }
  result = result.replace(/"\\\\U([0-9A-Fa-f]{8})") { $ in
    String(UnicodeScalar(parseInt($[1], radix: 16)))
  }
  return result
}

let escapeCharacters = [
  "0": "\0",
  "a": "\u{7}",
  "b": "\u{8}",
  "t": "\t",
  "n": "\n",
  "v": "\u{B}",
  "f": "\u{C}",
  "r": "\r",
  "e": "\u{1B}",
  " ": " ",
  "\"": "\"",
  "\\": "\\",
  "/": "/",
  "N": "\u{85}",
  "_": "\u{A0}",
  "L": "\u{2028}",
  "P": "\u{2029}"
]
