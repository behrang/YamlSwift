import Parsec

// [202]
func l_document_prefix () -> YamlParser<()> {
  return (
    c_byte_order_mark <<< many(l_comment)
    <|> optional(c_byte_order_mark) <<< many1(l_comment)
  )()
}

// [203]
func c_directives_end () -> YamlParser<()> {
  return (
    attempt(string("---")) >>> create(())
  )()
}

// [204]
func c_document_end () -> YamlParser<()> {
  return (
    attempt(string("...")) >>> create(())
  )()
}

// [205]
func l_document_suffix () -> YamlParser<()> {
  return (
    c_document_end <<< s_l_comments
  )()
}

// [206]
func c_forbidden () -> YamlParser<()> {
  return (
    start_of_line >>>
    ( c_directives_end <|> c_document_end )
    >>> ( b_char >>> create(()) <|> s_white >>> create(()) <|> eof )
  )()
}

// [207]
func l_bare_document () -> YamlParser<Node> {
  return (
    s_l_block_node(-1, .block_in)
  )()
}

// [208]
func l_explicit_document () -> YamlParser<Node> {
  return (
    c_directives_end >>> ( attempt(l_bare_document) <|> ( e_node <<< s_l_comments ) )
  )()
}

// [209]
func l_directive_document () -> YamlParser<Node> {
  return (
    many1(l_directive) >>- process_directives >>> l_explicit_document
  )()
}

func process_directives (_ directives: [(String, [String])]) -> YamlParserClosure<()> {
  if directives.filter({ $0.0 == "YAML" }).count > 1 {
    return unexpected("found more than one YAML directive")
  }
  var handles: [String: String] = [:]
  let tags = directives.filter({ $0.0 == "TAG" }).map({ $0.1 })
  tags.forEach{ tag in
    handles[tag[0]] = tag[1]
  }
  if handles.count < tags.count {
    return unexpected("found more than one TAG directive for the same handle")
  }
  return modifyState({ state in
    var modified = state
    handles.forEach{ (handle, pre) in
      modified.handles[handle] = pre
    }
    return modified
  })
}

// [210]
func l_any_document () -> YamlParser<Node> {
  return (
    l_directive_document <|> l_explicit_document <|> l_bare_document
  )()
}

// [211]
func l_yaml_stream () -> YamlParser<[Node]> {
  return (
    many(l_document_prefix) >>> optionMaybe(l_any_document) >>- { node in
      many(
        ( many1(l_document_suffix) >>> many(l_document_prefix) >>> optionMaybe(l_any_document) )
      <|>
        ( many1(l_document_prefix) >>> optionMaybe(l_explicit_document) )
      <|>
        ( many(l_document_prefix) >>> l_explicit_document >>- { create(.some($0)) } )
      ) >>- { nodes in
        create(prepend(node, nodes).filter { $0 != nil }.map { $0! })
      }
    }
  )()
}
