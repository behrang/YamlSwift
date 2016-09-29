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
func createContextValue (_ context: Context) -> (Yaml) -> ContextValue {
  return { value in (context, value) }
}
func getContext (_ cv: ContextValue) -> Context {
  return cv.context
}
func getValue (_ cv: ContextValue) -> Yaml {
  return cv.value
}

func parseDoc (_ tokens: [TokenMatch]) -> Result<Yaml> {
  let c = lift(Context(tokens))
  let cv = c >>=- parseHeader >>=- parse
  let v = cv >>- getValue
  return cv
      >>- getContext
      >>- ignoredocend
      >>=- expect(TokenType.end, message: "expected end")
      >>| v
}

func parseDocs (_ tokens: [TokenMatch]) -> Result<[Yaml]> {
  return parseDocs([])(Context(tokens))
}

func parseDocs (_ acc: [Yaml]) -> (Context) -> Result<[Yaml]> {
  return { context in
    if peekType(context) == .end {
      return lift(acc)
    }
    let cv = lift(context)
        >>=- parseHeader
        >>=- parse
    let v = cv
        >>- getValue
    let c = cv
        >>- getContext
        >>- ignoredocend
    let a = appendToArray(acc) <^> v
    return parseDocs <^> a <*> c |> join
  }
}

func peekType (_ context: Context) -> TokenType {
  return context.tokens[0].type
}

func peekMatch (_ context: Context) -> String {
  return context.tokens[0].match
}

func advance (_ context: Context) -> Context {
  var tokens = context.tokens
  tokens.remove(at: 0)
  return Context(tokens, context.aliases)
}

func ignorespace (_ context: Context) -> Context {
  if ![.comment, .space, .newLine].contains(peekType(context)) {
    return context
  }
  return ignorespace(advance(context))
}

func ignoredocend (_ context: Context) -> Context {
  if ![.comment, .space, .newLine, .docend].contains(peekType(context)) {
    return context
  }
  return ignoredocend(advance(context))
}

func expect (_ type: TokenType, message: String) -> (Context) -> Result<Context> {
  return { context in
    let check = peekType(context) == type
    return `guard`(error(message)(context), check: check)
        >>| lift(advance(context))
  }
}

func expectVersion (_ context: Context) -> Result<Context> {
  let version = peekMatch(context)
  let check = ["1.1", "1.2"].contains(version)
  return `guard`(error("invalid yaml version")(context), check: check)
      >>| lift(advance(context))
}

func error (_ message: String) -> (Context) -> String {
  return { context in
    let text = recreateText("", context: context) |> escapeErrorContext
    return "\(message), \(text)"
  }
}

func recreateText (_ string: String, context: Context) -> String {
  if string.characters.count >= 50 || peekType(context) == .end {
    return string
  }
  return recreateText(string + peekMatch(context), context: advance(context))
}

func parseHeader (_ context: Context) -> Result<Context> {
  return parseHeader(true)(Context(context.tokens, [:]))
}

func parseHeader (_ yamlAllowed: Bool) -> (Context) -> Result<Context> {
  return { context in
    switch peekType(context) {

    case .comment, .space, .newLine:
      return lift(context)
          >>- advance
          >>=- parseHeader(yamlAllowed)

    case .yamlDirective:
      let err = "duplicate yaml directive"
      return `guard`(error(err)(context), check: yamlAllowed)
          >>| lift(context)
          >>- advance
          >>=- expect(TokenType.space, message: "expected space")
          >>=- expectVersion
          >>=- parseHeader(false)

    case .docStart:
      return lift(advance(context))

    default:
      return `guard`(error("expected ---")(context), check: yamlAllowed)
          >>| lift(context)
    }
  }
}

func parse (_ context: Context) -> Result<ContextValue> {
  switch peekType(context) {

  case .comment, .space, .newLine:
    return parse(ignorespace(context))

  case .null:
    return lift((advance(context), nil))

  case ._true:
    return lift((advance(context), true))

  case ._false:
    return lift((advance(context), false))

  case .int:
    let m = peekMatch(context)
    // will throw runtime error if overflows
    let v = Yaml.int(parseint(m, radix: 10))
    return lift((advance(context), v))

  case .intOct:
    let m = peekMatch(context) |> replace(regex("0o"), template: "")
    // will throw runtime error if overflows
    let v = Yaml.int(parseint(m, radix: 8))
    return lift((advance(context), v))

  case .intHex:
    let m = peekMatch(context) |> replace(regex("0x"), template: "")
    // will throw runtime error if overflows
    let v = Yaml.int(parseint(m, radix: 16))
    return lift((advance(context), v))

  case .intSex:
    let m = peekMatch(context)
    let v = Yaml.int(parseint(m, radix: 60))
    return lift((advance(context), v))

  case .infinityP:
    return lift((advance(context), .double(Double.infinity)))

  case .infinityN:
    return lift((advance(context), .double(Double.infinity)))

  case .nan:
    return lift((advance(context), .double(Double.nan)))

  case .double:
    let m = NSString(string: peekMatch(context))
    return lift((advance(context), .double(m.doubleValue)))

  case .dash:
    return parseBlockSeq(context)

  case .openSB:
    return parseFlowSeq(context)

  case .openCB:
    return parseFlowMap(context)

  case .questionMark:
    return parseBlockMap(context)

  case .stringDQ, .stringSQ, .string:
    return parseBlockMapOrString(context)

  case .literal:
    return parseliteral(context)

  case .folded:
    let cv = parseliteral(context)
    let c = cv >>- getContext
    let v = cv
        >>- getValue
        >>- { value in Yaml.string(foldBlock(value.string ?? "")) }
    return createContextValue <^> c <*> v

  case .indent:
    let cv = parse(advance(context))
    let v = cv >>- getValue
    let c = cv
        >>- getContext
        >>- ignorespace
        >>=- expect(TokenType.dedent, message: "expected dedent")
    return createContextValue <^> c <*> v

  case .anchor:
    let m = peekMatch(context)
    let name = m.substring(from: m.index(after: m.startIndex))
    let cv = parse(advance(context))
    let v = cv >>- getValue
    let c = addalias(name) <^> v <*> (cv >>- getContext)
    return createContextValue <^> c <*> v

  case .alias:
    let m = peekMatch(context)
    let name = m.substring(from: m.index(after: m.startIndex))
    let value = context.aliases[name]
    let err = "unknown alias \(name)"
    return `guard`(error(err)(context), check: value != nil)
        >>| lift((advance(context), value ?? nil))

  case .end, .dedent:
    return lift((context, nil))

  default:
    return fail(error("unexpected type \(peekType(context))")(context))

  }
}

func addalias (_ name: String) -> (Yaml) -> (Context) -> Context {
  return { value in
    return { context in
      var aliases = context.aliases
      aliases[name] = value
      return Context(context.tokens, aliases)
    }
  }
}

func appendToArray (_ array: [Yaml]) -> (Yaml) -> [Yaml] {
  return { value in
    return array + [value]
  }
}

func putToMap (_ map: [Yaml: Yaml]) -> (Yaml) -> (Yaml) -> [Yaml: Yaml] {
  return { key in
    return { value in
      var map = map
      map[key] = value
      return map
    }
  }
}

func checkkeyUniqueness (_ acc: [Yaml: Yaml]) -> (_ context: Context, _ key: Yaml)
    -> Result<ContextValue> {
      return { (context, key) in
        let err = "duplicate key \(key)"
        return `guard`(error(err)(context), check: !acc.keys.contains(key))
            >>| lift((context, key))
      }
}

func parseFlowSeq (_ context: Context) -> Result<ContextValue> {
  return lift(context)
      >>=- expect(TokenType.openSB, message: "expected [")
      >>=- parseFlowSeq([])
}

func parseFlowSeq (_ acc: [Yaml]) -> (Context) -> Result<ContextValue> {
  return { context in
    if peekType(context) == .closeSB {
      return lift((advance(context), .array(acc)))
    }
    let cv = lift(context)
        >>- ignorespace
        >>=- (acc.count == 0 ? lift : expect(TokenType.comma, message: "expected comma"))
        >>- ignorespace
        >>=- parse
    let v = cv >>- getValue
    let c = cv
        >>- getContext
        >>- ignorespace
    let a = appendToArray(acc) <^> v
    return parseFlowSeq <^> a <*> c |> join
  }
}

func parseFlowMap (_ context: Context) -> Result<ContextValue> {
  return lift(context)
      >>=- expect(TokenType.openCB, message: "expected {")
      >>=- parseFlowMap([:])
}

func parseFlowMap (_ acc: [Yaml: Yaml]) -> (Context) -> Result<ContextValue> {
  return { context in
    if peekType(context) == .closeCB {
      return lift((advance(context), .dictionary(acc)))
    }
    let ck = lift(context)
        >>- ignorespace
        >>=- (acc.count == 0 ? lift : expect(TokenType.comma, message: "expected comma"))
        >>- ignorespace
        >>=- parseString
        >>=- checkkeyUniqueness(acc)
    let k = ck >>- getValue
    let cv = ck
        >>- getContext
        >>=- expect(TokenType.colon, message: "expected colon")
        >>=- parse
    let v = cv >>- getValue
    let c = cv
        >>- getContext
        >>- ignorespace
    let a = putToMap(acc) <^> k <*> v
    return parseFlowMap <^> a <*> c |> join
  }
}

func parseBlockSeq (_ context: Context) -> Result<ContextValue> {
  return parseBlockSeq([])(context)
}

func parseBlockSeq (_ acc: [Yaml]) -> (Context) -> Result<ContextValue> {
  return { context in
    if peekType(context) != .dash {
      return lift((context, .array(acc)))
    }
    let cv = lift(context)
        >>- advance
        >>=- expect(TokenType.indent, message: "expected indent after dash")
        >>- ignorespace
        >>=- parse
    let v = cv >>- getValue
    let c = cv
        >>- getContext
        >>- ignorespace
        >>=- expect(TokenType.dedent, message: "expected dedent after dash indent")
        >>- ignorespace
    let a = appendToArray(acc) <^> v
    return parseBlockSeq <^> a <*> c |> join
  }
}

func parseBlockMap (_ context: Context) -> Result<ContextValue> {
  return parseBlockMap([:])(context)
}

func parseBlockMap (_ acc: [Yaml: Yaml]) -> (Context) -> Result<ContextValue> {
  return { context in
    switch peekType(context) {

    case .questionMark:
      return parsequestionMarkkeyValue(acc)(context)

    case .string, .stringDQ, .stringSQ:
      return parseStringkeyValue(acc)(context)

    default:
      return lift((context, .dictionary(acc)))
    }
  }
}

func parsequestionMarkkeyValue (_ acc: [Yaml: Yaml]) -> (Context) -> Result<ContextValue> {
  return { context in
    let ck = lift(context)
        >>=- expect(TokenType.questionMark, message: "expected ?")
        >>=- parse
        >>=- checkkeyUniqueness(acc)
    let k = ck >>- getValue
    let cv = ck
        >>- getContext
        >>- ignorespace
        >>=- parsecolonValueOrNil
    let v = cv >>- getValue
    let c = cv
        >>- getContext
        >>- ignorespace
    let a = putToMap(acc) <^> k <*> v
    return parseBlockMap <^> a <*> c |> join
  }
}

func parsecolonValueOrNil (_ context: Context) -> Result<ContextValue> {
  if peekType(context) != .colon {
    return lift((context, nil))
  }
  return parsecolonValue(context)
}

func parsecolonValue (_ context: Context) -> Result<ContextValue> {
  return lift(context)
      >>=- expect(TokenType.colon, message: "expected colon")
      >>- ignorespace
      >>=- parse
}

func parseStringkeyValue (_ acc: [Yaml: Yaml]) -> (Context) -> Result<ContextValue> {
  return { context in
    let ck = lift(context)
        >>=- parseString
        >>=- checkkeyUniqueness(acc)
    let k = ck >>- getValue
    let cv = ck
        >>- getContext
        >>- ignorespace
        >>=- parsecolonValue
    let v = cv >>- getValue
    let c = cv
        >>- getContext
        >>- ignorespace
    let a = putToMap(acc) <^> k <*> v
    return parseBlockMap <^> a <*> c |> join
  }
}

func parseString (_ context: Context) -> Result<ContextValue> {
  switch peekType(context) {

  case .string:
    let m = normalizeBreaks(peekMatch(context))
    let folded = m |> replace(regex("^[ \\t\\n]+|[ \\t\\n]+$"), template: "") |> foldFlow
    return lift((advance(context), .string(folded)))

  case .stringDQ:
    let m = unwrapQuotedString(normalizeBreaks(peekMatch(context)))
    return lift((advance(context), .string(unescapedoubleQuotes(foldFlow(m)))))

  case .stringSQ:
    let m = unwrapQuotedString(normalizeBreaks(peekMatch(context)))
    return lift((advance(context), .string(unescapeSingleQuotes(foldFlow(m)))))

  default:
    return fail(error("expected string")(context))
  }
}

func parseBlockMapOrString (_ context: Context) -> Result<ContextValue> {
  let match = peekMatch(context)
  // should spaces before colon be ignored?
  return context.tokens[1].type != .colon || matches(match, regex: regex("\n"))
      ? parseString(context)
      : parseBlockMap(context)
}

func foldBlock (_ block: String) -> String {
  let (body, trail) = block |> splitTrail(regex("\\n*$"))
  return (body
      |> replace(regex("^([^ \\t\\n].*)\\n(?=[^ \\t\\n])", options: "m"), template: "$1 ")
      |> replace(
            regex("^([^ \\t\\n].*)\\n(\\n+)(?![ \\t])", options: "m"), template: "$1$2")
      ) + trail
}

func foldFlow (_ flow: String) -> String {
  let (lead, rest) = flow |> splitLead(regex("^[ \\t]+"))
  let (body, trail) = rest |> splitTrail(regex("[ \\t]+$"))
  let folded = body
      |> replace(regex("^[ \\t]+|[ \\t]+$|\\\\\\n", options: "m"), template: "")
      |> replace(regex("(^|.)\\n(?=.|$)"), template: "$1 ")
      |> replace(regex("(.)\\n(\\n+)"), template: "$1$2")
  return lead + folded + trail
}

func parseliteral (_ context: Context) -> Result<ContextValue> {
  let literal = peekMatch(context)
  let blockContext = advance(context)
  let chomps = ["-": -1, "+": 1]
  let chomp = chomps[literal |> replace(regex("[^-+]"), template: "")] ?? 0
  let indent = parseint(literal |> replace(regex("[^1-9]"), template: ""), radix: 10)
  let headerPattern = regex("^(\\||>)([1-9][-+]|[-+]?[1-9]?)( |$)")
  let error0 = "invalid chomp or indent header"
  let c = `guard`(error(error0)(context),
        check: matches(literal, regex: headerPattern!))
      >>| lift(blockContext)
      >>=- expect(TokenType.string, message: "expected scalar block")
  let block = peekMatch(blockContext)
      |> normalizeBreaks
  let (lead, _) = block
      |> splitLead(regex("^( *\\n)* {1,}(?! |\\n|$)"))
  let foundindent = lead
      |> replace(regex("^( *\\n)*"), template: "")
      |> count
  let effectiveindent = indent > 0 ? indent : foundindent
  let invalidPattern =
      regex("^( {0,\(effectiveindent)}\\n)* {\(effectiveindent + 1),}\\n")
  let check1 = matches(block, regex: invalidPattern!)
  let check2 = indent > 0 && foundindent < indent
  let trimmed = block
      |> replace(regex("^ {0,\(effectiveindent)}"), template: "")
      |> replace(regex("\\n {0,\(effectiveindent)}"), template: "\n")
      |> (chomp == -1
          ? replace(regex("(\\n *)*$"), template: "")
          : chomp == 0
          ? replace(regex("(?=[^ ])(\\n *)*$"), template: "\n")
          : { s in s }
      )
  let error1 = "leading all-space line must not have too many spaces"
  let error2 = "less indented block scalar than the indicated level"
  return c
      >>| `guard`(error(error1)(blockContext), check: !check1)
      >>| `guard`(error(error2)(blockContext), check: !check2)
      >>| c
      >>- { context in (context, .string(trimmed))}
}

func parseint (_ string: String, radix: Int) -> Int {
  let (sign, str) = splitLead(regex("^[-+]"))(string)
  let multiplier = (sign == "-" ? -1 : 1)
  let ints = radix == 60
      ? toSexints(str)
      : toints(str)
  return multiplier * ints.reduce(0, { acc, i in acc * radix + i })
}

func toSexints (_ string: String) -> [Int] {
  return string.components(separatedBy: ":").map {
    c in Int(c) ?? 0
  }
}

func toints (_ string: String) -> [Int] {
  return string.unicodeScalars.map {
    c in
    switch c {
    case "0"..."9": return Int(c.value) - Int(("0" as UnicodeScalar).value)
    case "a"..."z": return Int(c.value) - Int(("a" as UnicodeScalar).value) + 10
    case "A"..."Z": return Int(c.value) - Int(("A" as UnicodeScalar).value) + 10
    default: fatalError("invalid digit \(c)")
    }
  }
}

func normalizeBreaks (_ s: String) -> String {
  return replace(regex("\\r\\n|\\r"), template: "\n")(s)
}

func unwrapQuotedString (_ s: String) -> String {
  return s[s.index(after: s.startIndex)..<s.index(before: s.endIndex)]
}

func unescapeSingleQuotes (_ s: String) -> String {
  return replace(regex("''"), template: "'")(s)
}

func unescapedoubleQuotes (_ input: String) -> String {
  return input
    |> replace(regex("\\\\([0abtnvfre \"\\/N_LP])"))
        { escapeCharacters[$0[1]] ?? "" }
    |> replace(regex("\\\\x([0-9A-Fa-f]{2})"))
        { String(describing: UnicodeScalar(parseint($0[1], radix: 16))) }
    |> replace(regex("\\\\u([0-9A-Fa-f]{4})"))
        { String(describing: UnicodeScalar(parseint($0[1], radix: 16))) }
    |> replace(regex("\\\\U([0-9A-Fa-f]{8})"))
        { String(describing: UnicodeScalar(parseint($0[1], radix: 16))) }
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
