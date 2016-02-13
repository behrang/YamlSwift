import Foundation

struct Context {
  let tokens: [TokenMatch]
  let aliases: [String: Yaml]

  init (_ tokens: [TokenMatch], _ aliases: [String: Yaml] = [:]) {
    self.tokens = tokens
    self.aliases = aliases
  }
}

typealias ContextValue = (context: Context, value: Yaml)
func createContextValue (context: Context) -> Yaml -> ContextValue {
  return { value in (context, value) }
}
func getContext (cv: ContextValue) -> Context {
  return cv.context
}
func getValue (cv: ContextValue) -> Yaml {
  return cv.value
}

func parseDoc (tokens: [TokenMatch]) -> Result<Yaml> {
  let c = lift(Context(tokens))
  let cv = c >>=- parseHeader >>=- parse
  let v = cv >>- getValue
  return cv
      >>- getContext
      >>- ignoreDocEnd
      >>=- expect(TokenType.End, message: "expected end")
      >>| v
}

func parseDocs (tokens: [TokenMatch]) -> Result<[Yaml]> {
  return parseDocs([])(Context(tokens))
}

func parseDocs (acc: [Yaml]) -> Context -> Result<[Yaml]> {
  return { context in
    if peekType(context) == .End {
      return lift(acc)
    }
    let cv = lift(context)
        >>=- parseHeader
        >>=- parse
    let v = cv
        >>- getValue
    let c = cv
        >>- getContext
        >>- ignoreDocEnd
    let a = appendToArray(acc) <^> v
    return parseDocs <^> a <*> c |> join
  }
}

func peekType (context: Context) -> TokenType {
  return context.tokens[0].type
}

func peekMatch (context: Context) -> String {
  return context.tokens[0].match
}

func advance (context: Context) -> Context {
  var tokens = context.tokens
  tokens.removeAtIndex(0)
  return Context(tokens, context.aliases)
}

func ignoreSpace (context: Context) -> Context {
  if ![.Comment, .Space, .NewLine].contains(peekType(context)) {
    return context
  }
  return ignoreSpace(advance(context))
}

func ignoreDocEnd (context: Context) -> Context {
  if ![.Comment, .Space, .NewLine, .DocEnd].contains(peekType(context)) {
    return context
  }
  return ignoreDocEnd(advance(context))
}

func expect (type: TokenType, message: String) -> Context -> Result<Context> {
  return { context in
    let check = peekType(context) == type
    return `guard`(error(message)(context), check: check)
        >>| lift(advance(context))
  }
}

func expectVersion (context: Context) -> Result<Context> {
  let version = peekMatch(context)
  let check = ["1.1", "1.2"].contains(version)
  return `guard`(error("invalid yaml version")(context), check: check)
      >>| lift(advance(context))
}

func error (message: String) -> Context -> String {
  return { context in
    let text = recreateText("", context: context) |> escapeErrorContext
    return "\(message), \(text)"
  }
}

func recreateText (string: String, context: Context) -> String {
  if string.characters.count >= 50 || peekType(context) == .End {
    return string
  }
  return recreateText(string + peekMatch(context), context: advance(context))
}

func parseHeader (context: Context) -> Result<Context> {
  return parseHeader(true)(Context(context.tokens, [:]))
}

func parseHeader (yamlAllowed: Bool) -> Context -> Result<Context> {
  return { context in
    switch peekType(context) {

    case .Comment, .Space, .NewLine:
      return lift(context)
          >>- advance
          >>=- parseHeader(yamlAllowed)

    case .YamlDirective:
      let err = "duplicate yaml directive"
      return `guard`(error(err)(context), check: yamlAllowed)
          >>| lift(context)
          >>- advance
          >>=- expect(TokenType.Space, message: "expected space")
          >>=- expectVersion
          >>=- parseHeader(false)

    case .DocStart:
      return lift(advance(context))

    default:
      return `guard`(error("expected ---")(context), check: yamlAllowed)
          >>| lift(context)
    }
  }
}

func parse (context: Context) -> Result<ContextValue> {
  switch peekType(context) {

  case .Comment, .Space, .NewLine:
    return parse(ignoreSpace(context))

  case .Null:
    return lift((advance(context), nil))

  case .True:
    return lift((advance(context), true))

  case .False:
    return lift((advance(context), false))

  case .Int:
    let m = peekMatch(context)
    // will throw runtime error if overflows
    let v = Yaml.Int(parseInt(m, radix: 10))
    return lift((advance(context), v))

  case .IntOct:
    let m = peekMatch(context).replace("0o", with: "")
    // will throw runtime error if overflows
    let v = Yaml.Int(parseInt(m, radix: 8))
    return lift((advance(context), v))

  case .IntHex:
    let m = peekMatch(context).replace("0x", with: "")
    // will throw runtime error if overflows
    let v = Yaml.Int(parseInt(m, radix: 16))
    return lift((advance(context), v))

  case .IntSex:
    let m = peekMatch(context)
    let v = Yaml.Int(parseInt(m, radix: 60))
    return lift((advance(context), v))

  case .InfinityP:
    return lift((advance(context), .Double(Double.infinity)))

  case .InfinityN:
    return lift((advance(context), .Double(-Double.infinity)))

  case .NaN:
    return lift((advance(context), .Double(Double.NaN)))

  case .Double:
    let m = peekMatch(context) as NSString
    return lift((advance(context), .Double(m.doubleValue)))

  case .Dash:
    return parseBlockSeq(context)

  case .OpenSB:
    return parseFlowSeq(context)

  case .OpenCB:
    return parseFlowMap(context)

  case .QuestionMark:
    return parseBlockMap(context)

  case .StringDQ, .StringSQ, .String:
    return parseBlockMapOrString(context)

  case .Literal:
    return parseLiteral(context)

  case .Folded:
    let cv = parseLiteral(context)
    let c = cv >>- getContext
    let v = cv
        >>- getValue
        >>- { value in Yaml.String(foldBlock(value.string ?? "")) }
    return createContextValue <^> c <*> v

  case .Indent:
    let cv = parse(advance(context))
    let v = cv >>- getValue
    let c = cv
        >>- getContext
        >>- ignoreSpace
        >>=- expect(TokenType.Dedent, message: "expected dedent")
    return createContextValue <^> c <*> v

  case .Anchor:
    let m = peekMatch(context)
    let name = m.substringFromIndex(m.startIndex.successor())
    let cv = parse(advance(context))
    let v = cv >>- getValue
    let c = addAlias(name) <^> v <*> (cv >>- getContext)
    return createContextValue <^> c <*> v

  case .Alias:
    let m = peekMatch(context)
    let name = m.substringFromIndex(m.startIndex.successor())
    let value = context.aliases[name]
    let err = "unknown alias \(name)"
    return `guard`(error(err)(context), check: value != nil)
        >>| lift((advance(context), value ?? nil))

  case .End, .Dedent:
    return lift((context, nil))

  default:
    return fail(error("unexpected type \(peekType(context))")(context))

  }
}

func addAlias (name: String) -> Yaml -> Context -> Context {
  return { value in
    return { context in
      var aliases = context.aliases
      aliases[name] = value
      return Context(context.tokens, aliases)
    }
  }
}

func appendToArray (array: [Yaml]) -> Yaml -> [Yaml] {
  return { value in
    return array + [value]
  }
}

func putToMap (map: [Yaml: Yaml]) -> Yaml -> Yaml -> [Yaml: Yaml] {
  return { key in
    return { value in
      var map = map
      map[key] = value
      return map
    }
  }
}

func checkKeyUniqueness (acc: [Yaml: Yaml]) -> (context: Context, key: Yaml)
    -> Result<ContextValue> {
      return { (context, key) in
        let err = "duplicate key \(key)"
        return `guard`(error(err)(context), check: !acc.keys.contains(key))
            >>| lift((context, key))
      }
}

func parseFlowSeq (context: Context) -> Result<ContextValue> {
  return lift(context)
      >>=- expect(TokenType.OpenSB, message: "expected [")
      >>=- parseFlowSeq([])
}

func parseFlowSeq (acc: [Yaml]) -> Context -> Result<ContextValue> {
  return { context in
    if peekType(context) == .CloseSB {
      return lift((advance(context), .Array(acc)))
    }
    let cv = lift(context)
        >>- ignoreSpace
        >>=- (acc.count == 0 ? lift : expect(TokenType.Comma, message: "expected comma"))
        >>- ignoreSpace
        >>=- parse
    let v = cv >>- getValue
    let c = cv
        >>- getContext
        >>- ignoreSpace
    let a = appendToArray(acc) <^> v
    return parseFlowSeq <^> a <*> c |> join
  }
}

func parseFlowMap (context: Context) -> Result<ContextValue> {
  return lift(context)
      >>=- expect(TokenType.OpenCB, message: "expected {")
      >>=- parseFlowMap([:])
}

func parseFlowMap (acc: [Yaml: Yaml]) -> Context -> Result<ContextValue> {
  return { context in
    if peekType(context) == .CloseCB {
      return lift((advance(context), .Dictionary(acc)))
    }
    let ck = lift(context)
        >>- ignoreSpace
        >>=- (acc.count == 0 ? lift : expect(TokenType.Comma, message: "expected comma"))
        >>- ignoreSpace
        >>=- parseString
        >>=- checkKeyUniqueness(acc)
    let k = ck >>- getValue
    let cv = ck
        >>- getContext
        >>=- expect(TokenType.Colon, message: "expected colon")
        >>=- parse
    let v = cv >>- getValue
    let c = cv
        >>- getContext
        >>- ignoreSpace
    let a = putToMap(acc) <^> k <*> v
    return parseFlowMap <^> a <*> c |> join
  }
}

func parseBlockSeq (context: Context) -> Result<ContextValue> {
  return parseBlockSeq([])(context)
}

func parseBlockSeq (acc: [Yaml]) -> Context -> Result<ContextValue> {
  return { context in
    if peekType(context) != .Dash {
      return lift((context, .Array(acc)))
    }
    let cv = lift(context)
        >>- advance
        >>=- expect(TokenType.Indent, message: "expected indent after dash")
        >>- ignoreSpace
        >>=- parse
    let v = cv >>- getValue
    let c = cv
        >>- getContext
        >>- ignoreSpace
        >>=- expect(TokenType.Dedent, message: "expected dedent after dash indent")
        >>- ignoreSpace
    let a = appendToArray(acc) <^> v
    return parseBlockSeq <^> a <*> c |> join
  }
}

func parseBlockMap (context: Context) -> Result<ContextValue> {
  return parseBlockMap([:])(context)
}

func parseBlockMap (acc: [Yaml: Yaml]) -> Context -> Result<ContextValue> {
  return { context in
    switch peekType(context) {

    case .QuestionMark:
      return parseQuestionMarkKeyValue(acc)(context)

    case .String, .StringDQ, .StringSQ:
      return parseStringKeyValue(acc)(context)

    default:
      return lift((context, .Dictionary(acc)))
    }
  }
}

func parseQuestionMarkKeyValue (acc: [Yaml: Yaml]) -> Context -> Result<ContextValue> {
  return { context in
    let ck = lift(context)
        >>=- expect(TokenType.QuestionMark, message: "expected ?")
        >>=- parse
        >>=- checkKeyUniqueness(acc)
    let k = ck >>- getValue
    let cv = ck
        >>- getContext
        >>- ignoreSpace
        >>=- parseColonValueOrNil
    let v = cv >>- getValue
    let c = cv
        >>- getContext
        >>- ignoreSpace
    let a = putToMap(acc) <^> k <*> v
    return parseBlockMap <^> a <*> c |> join
  }
}

func parseColonValueOrNil (context: Context) -> Result<ContextValue> {
  if peekType(context) != .Colon {
    return lift((context, nil))
  }
  return parseColonValue(context)
}

func parseColonValue (context: Context) -> Result<ContextValue> {
  return lift(context)
      >>=- expect(TokenType.Colon, message: "expected colon")
      >>- ignoreSpace
      >>=- parse
}

func parseStringKeyValue (acc: [Yaml: Yaml]) -> Context -> Result<ContextValue> {
  return { context in
    let ck = lift(context)
        >>=- parseString
        >>=- checkKeyUniqueness(acc)
    let k = ck >>- getValue
    let cv = ck
        >>- getContext
        >>- ignoreSpace
        >>=- parseColonValue
    let v = cv >>- getValue
    let c = cv
        >>- getContext
        >>- ignoreSpace
    let a = putToMap(acc) <^> k <*> v
    return parseBlockMap <^> a <*> c |> join
  }
}

func parseString (context: Context) -> Result<ContextValue> {
  switch peekType(context) {

  case .String:
    let m = normalizeBreaks(peekMatch(context))
    let folded = m.replace("^[ \\t\\n]+|[ \\t\\n]+$", with: "") |> foldFlow
    return lift((advance(context), .String(folded)))

  case .StringDQ:
    let m = unwrapQuotedString(normalizeBreaks(peekMatch(context)))
    return lift((advance(context), .String(unescapeDoubleQuotes(foldFlow(m)))))

  case .StringSQ:
    let m = unwrapQuotedString(normalizeBreaks(peekMatch(context)))
    return lift((advance(context), .String(unescapeSingleQuotes(foldFlow(m)))))

  default:
    return fail(error("expected string")(context))
  }
}

func parseBlockMapOrString (context: Context) -> Result<ContextValue> {
  let match = peekMatch(context)
  // should spaces before colon be ignored?
  return context.tokens[1].type != .Colon || matches(match, regex: regex("\n"))
      ? parseString(context)
      : parseBlockMap(context)
}

func foldBlock (block: String) -> String {
  let (body, trail) = block |> splitTrail(regex("\\n*$"))
  return body
      .replace("^([^ \\t\\n].*)\\n(?=[^ \\t\\n])", with: "$1 ")
      .replace( "^([^ \\t\\n].*)\\n(\\n+)(?![ \\t])", with: "$1$2")
      + trail
}

func foldFlow (flow: String) -> String {
  let (lead, rest) = flow |> splitLead(regex("^[ \\t]+"))
  let (body, trail) = rest |> splitTrail(regex("[ \\t]+$"))
  let folded = body
      .replace("^[ \\t]+|[ \\t]+$|\\\\\\n", with: "")
      .replace("(^|.)\\n(?=.|$)", with: "$1 ")
      .replace("(.)\\n(\\n+)", with: "$1$2")
  return lead + folded + trail
}

func parseLiteral (context: Context) -> Result<ContextValue> {
  let literal = peekMatch(context)
  let blockContext = advance(context)
  let chomps = ["-": -1, "+": 1]
  let chomp = chomps[literal.replace("[^-+]", with: "")] ?? 0
  let indent = parseInt(literal.replace("[^1-9]", with: ""), radix: 10)
  let headerPattern = regex("^(\\||>)([1-9][-+]|[-+]?[1-9]?)( |$)")
  let error0 = "invalid chomp or indent header"
  let c = `guard`(error(error0)(context),
        check: matches(literal, regex: headerPattern))
      >>| lift(blockContext)
      >>=- expect(TokenType.String, message: "expected scalar block")
  let block = peekMatch(blockContext)
      |> normalizeBreaks
  let (lead, _) = block
      |> splitLead(regex("^( *\\n)* {1,}(?! |\\n|$)"))
  let foundIndent = lead.replace("^( *\\n)*", with: "").count
  let effectiveIndent = indent > 0 ? indent : foundIndent
  let invalidPattern =
      regex("^( {0,\(effectiveIndent)}\\n)* {\(effectiveIndent + 1),}\\n")
  let check1 = matches(block, regex: invalidPattern)
  let check2 = indent > 0 && foundIndent < indent
  let trimmed =  {
    chomp == -1
      ? $0.replace("(\\n *)*$", with: "")
      : (
        chomp == 0
        ? $0.replace("(?=[^ ])(\\n *)*$", with: "\n")
        : $0
      )
    }(
      block
        .replace("^ {0,\(effectiveIndent)}"  , with: "")
        .replace("\\n {0,\(effectiveIndent)}", with: "\n")
    )

  let error1 = "leading all-space line must not have too many spaces"
  let error2 = "less indented block scalar than the indicated level"
  return c
      >>| `guard`(error(error1)(blockContext), check: !check1)
      >>| `guard`(error(error2)(blockContext), check: !check2)
      >>| c
      >>- { context in (context, .String(trimmed))}
}

func parseInt (string: String, radix: Int) -> Int {
  let (sign, str) = splitLead(regex("^[-+]"))(string)
  let multiplier = (sign == "-" ? -1 : 1)
  let ints = radix == 60
      ? toSexInts(str)
      : toInts(str)
  return multiplier * ints.reduce(0, combine: { acc, i in acc * radix + i })
}

func toSexInts (string: String) -> [Int] {
  return string.componentsSeparatedByString(":").map {
    c in Int(c) ?? 0
  }
}

func toInts (string: String) -> [Int] {
  return string.unicodeScalars.map {
    c in
    switch c {
    case "0"..."9": return Int(c.value) - Int(UnicodeScalar("0").value)
    case "a"..."z": return Int(c.value) - Int(UnicodeScalar("a").value) + 10
    case "A"..."Z": return Int(c.value) - Int(UnicodeScalar("A").value) + 10
    default: fatalError("invalid digit \(c)")
    }
  }
}

func normalizeBreaks (s: String) -> String {
  return s.replace("\\r\\n|\\r", with: "\n")
}

func unwrapQuotedString (s: String) -> String {
  return s[s.startIndex.successor()..<s.endIndex.predecessor()]
}

func unescapeSingleQuotes (s: String) -> String {
  return s.replace("''", with: "'")
}

func unescapeDoubleQuotes (input: String) -> String {
  return input
    |> replace(regex("\\\\([0abtnvfre \"\\/N_LP])"))
        { $ in escapeCharacters[$[1]] ?? "" }
    |> replace(regex("\\\\x([0-9A-Fa-f]{2})"))
        { $ in String(UnicodeScalar(parseInt($[1], radix: 16))) }
    |> replace(regex("\\\\u([0-9A-Fa-f]{4})"))
        { $ in String(UnicodeScalar(parseInt($[1], radix: 16))) }
    |> replace(regex("\\\\U([0-9A-Fa-f]{8})"))
        { $ in String(UnicodeScalar(parseInt($[1], radix: 16))) }
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
