import Parsec

// [202]
func l_document_prefix () -> YamlParser<()> {
  return (
    c_byte_order_mark >>> create(()) <<< many(l_comment)
    <|> optional(c_byte_order_mark) <<< many1(l_comment)
  )()
}

// [203]
func c_directives_end () -> YamlParser<()> {
  return (
    string("---") >>> create(())
  )()
}

// [204]
func c_document_end () -> YamlParser<()> {
  return (
    string("...") >>> create(())
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
    many1(l_directive) >>> l_explicit_document
  )()
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
