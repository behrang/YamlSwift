import Parsec

enum Chomp {
  case strip
  case clip
  case keep
}

func to_dictionary (_ entries: [(Node, Node)]) -> YamlParserClosure<Node> {
  var r: [Node: Node] = [:]
  for (key, value) in entries {
    if r[key] != nil {
      return unexpected("found duplicate block mapping key: \(key)")
    }
    r[key] = value
  }
  return create(.mapping(r, tag_mapping))
}

// [162]
func c_b_block_header (_ n: Int) -> YamlParserClosure<(indent: Int, chomp: Chomp)> {
  return {(
    (
      c_indentation_indicator(n) >>- { m in
        c_chomping_indicator >>- { t in
          create((m, t))
        }
      } <|> c_chomping_indicator >>- { t in
        c_indentation_indicator(n) >>- { m in
          create((m, t))
        }
      }
    ) <<< s_b_comment
  )()}
}

// [163]
func c_indentation_indicator (_ n: Int) -> YamlParserClosure<Int> {
  return {(
    oneOf("123456789") >>- { c in
      create(Int(String(c), radix: 10)!)
    } <|> lookAhead(s_b_comment >>> auto_detect(n))
  )()}
}

func auto_detect (_ n: Int) -> YamlParserClosure<Int> {
  return { (
    lookAhead(
      many(attempt(l_empty(n, .flow_out)))
      >>> many(s_space) >>- { ss in
        create(max(1, ss.count - n))
      }
    ) >>- { m in
      lookAhead(
        many(attempt(l_empty(n + m, .block_out)))
        >>> notFollowedBy(s_indent(n + m + 1))
      ) >>> create(m)
    }
  )()}
}

// [164]
func c_chomping_indicator () -> YamlParser<Chomp> {
  return (
        char("-") >>> create(.strip)
    <|> char("+") >>> create(.keep)
    <|> create(.clip)
  )()
}

// [165]
func b_chomped_last (_ t: Chomp) -> YamlParserClosure<String> {
  return {
    switch t {
    case .strip: return ( (b_non_content <|> eof) >>> create("") )()
    case .clip, .keep:
      return ( b_as_line_feed >>> create("\n") <|> eof >>> create("") )()
    }
  }
}

// [166]
func l_chomped_empty (_ n: Int, _ t: Chomp) -> YamlParserClosure<String> {
  return {
    switch t {
    case .strip, .clip: return ( l_strip_empty(n) >>> create("") )()
    case .keep: return l_keep_empty(n)()
    }
  }
}

// [167]
func l_strip_empty (_ n: Int) -> YamlParserClosure<()> {
  return {(
    many(attempt(s_indent_less_equal(n) >>> b_non_content))
    >>> optional(attempt(l_trail_comments(n)))
  )()}
}

// [168]
func l_keep_empty (_ n: Int) -> YamlParserClosure<String> {
  return {(
    many(attempt(l_empty(n, .block_in))) >>- { cs in
      create(String(cs))
    } <<< optional(attempt(l_trail_comments(n)))
  )()}
}

// [169]
func l_trail_comments (_ n: Int) -> YamlParserClosure<()> {
  return {(
    s_indent_less_than(n) >>> c_nb_comment_text >>> b_comment
    <<< many(l_comment)
  )()}
}

// [170]
func c_l_literal (_ n: Int) -> YamlParserClosure<String> {
  return {(
    char("|") >>> c_b_block_header(n) >>- { (m, t) in
      l_literal_content(n + m, t)
    }
  )()}
}

// [171]
func l_nb_literal_text (_ n: Int) -> YamlParserClosure<String> {
  return {(
    many(attempt(l_empty(n, .block_in))) <<< s_indent(n) >>- { bs in
      (notFollowedBy(c_forbidden) <?> "no document markers") >>>
      many1(nb_char) >>- { xs in
        create(String(bs) + String(xs))
      }
    }
  )()}
}

// [172]
func b_nb_literal_next (_ n: Int) -> YamlParserClosure<String> {
  return {(
    b_as_line_feed >>- { b in
      l_nb_literal_text(n) >>- { s in
        create(String(b) + s)
      }
    }
  )()}
}

// [173]
func l_literal_content (_ n: Int, _ t: Chomp) -> YamlParserClosure<String> {
  return {(
    option("", attempt(l_nb_literal_text(n) >>- { s in
      many(attempt(b_nb_literal_next(n))) >>- { ns in
        b_chomped_last(t) >>- { b in
          create(s + ns.joined(separator: "") + b)
        }
      }
    })) >>- { content in
      l_chomped_empty(n, t) >>- { chomped in
        create(content + chomped)
      }
    }
  )()}
}

// [174]
func c_l_folded (_ n: Int) -> YamlParserClosure<String> {
  return {(
    char(">") >>> c_b_block_header(n) >>- { (m, t) in
      l_folded_content(n + m, t)
    }
  )()}
}

// [175]
func s_nb_folded_text (_ n: Int) -> YamlParserClosure<String> {
  return {(
    (notFollowedBy(c_forbidden) <?> "no document markers") >>>
    s_indent(n) >>> ns_char >>- { x in
      many(nb_char) >>- { xs in
        create(String(x) + String(xs))
      }
    }
  )()}
}

// [176]
func l_nb_folded_lines (_ n: Int) -> YamlParserClosure<String> {
  return {(
    s_nb_folded_text(n) >>- { s in
      many(attempt(b_l_folded(n, .block_in) >>- { l in
        s_nb_folded_text(n) >>- { r in
          create(l + r)
        }
      })) >>- { ss in
        create(s + ss.joined(separator: ""))
      }
    }
  )()}
}

// [177]
func s_nb_spaced_text (_ n: Int) -> YamlParserClosure<String> {
  return {(
    s_indent(n) >>> s_white >>- { w in
      many(nb_char) >>- { xs in
        create(String(w) + String(xs))
      }
    }
  )()}
}

// [178]
func b_l_spaced (_ n: Int) -> YamlParserClosure<String> {
  return {(
    b_as_line_feed >>- { b in
      many(attempt(l_empty(n, .block_in))) >>- { bs in
        create(String(b) + String(bs))
      }
    }
  )()}
}

// [179]
func l_nb_spaced_lines (_ n: Int) -> YamlParserClosure<String> {
  return {(
    s_nb_spaced_text(n) >>- { s in
      many(attempt(b_l_spaced(n) >>- { l in
        s_nb_spaced_text(n) >>- { r in
          create(l + r)
        }
      })) >>- { ss in
        create(s + ss.joined(separator: ""))
      }
    }
  )()}
}

// [180]
func l_nb_same_lines (_ n: Int) -> YamlParserClosure<String> {
  return {(
    many(attempt(l_empty(n, .block_in))) >>- { bs in
      ( attempt(l_nb_folded_lines(n)) <|> l_nb_spaced_lines(n) ) >>- { r in
        create(String(bs) + r)
      }
    }
  )()}
}

// [181]
func l_nb_diff_lines (_ n: Int) -> YamlParserClosure<String> {
  return {(
    l_nb_same_lines(n) >>- { s in
      many(attempt(b_as_line_feed >>- { b in
        l_nb_same_lines(n) >>- { r in
          create(String(b) + r)
        }
      })) >>- { ls in
        create(s + ls.joined(separator: ""))
      }
    }
  )()}
}

// [182]
func l_folded_content (_ n: Int, _ t: Chomp) -> YamlParserClosure<String> {
  return {(
    option("", attempt(l_nb_diff_lines(n) >>- { s in
      b_chomped_last(t) >>- { b in
        create(s + b)
      }
    })) >>- { s in
      l_chomped_empty(n, t) >>- { r in
        create(s + r)
      }
    }
  )()}
}

// [183]
func l_block_sequence (_ n: Int) -> YamlParserClosure<Node> {
  return {(
    auto_detect(n) >>- { m in
      many1(attempt(s_indent(n + m) >>> c_l_block_seq_entry(n + m)))
      >>- { entries in create(.sequence(entries, tag_sequence)) }
    }
  )()}
}

// [184]
func c_l_block_seq_entry (_ n: Int) -> YamlParserClosure<Node> {
  return {(
    char("-") >>> notFollowedBy(ns_char) >>> s_l_block_indented(n, .block_in)
  )()}
}

// [185]
func s_l_block_indented (_ n: Int, _ c: Context) -> YamlParserClosure<Node> {
  return {(
    attempt(auto_detect_inline >>- { m in
      s_indent(m) >>>
      ( attempt(ns_l_compact_sequence(n + 1 + m)) <|> ns_l_compact_mapping(n + 1 + m))
    }) <|> attempt(s_l_block_node(n, c))
    <|> e_node <<< s_l_comments
  )()}
}

func auto_detect_inline () -> YamlParser<Int> {
  return lookAhead(
    many(s_space) >>- { ss in
      create(ss.count)
    }
  )()
}

// [186]
func ns_l_compact_sequence (_ n: Int) -> YamlParserClosure<Node> {
  return {(
    c_l_block_seq_entry(n) >>- { entry in
      many(attempt(s_indent(n) >>> c_l_block_seq_entry(n))) >>- { entries in
        create(.sequence(prepend(entry, entries), tag_sequence))
      }
    }
  )()}
}

// [187]
func l_block_mapping (_ n: Int) -> YamlParserClosure<Node> {
  return {(
    auto_detect(n) >>- { m in
      many1(attempt(s_indent(n + m) >>> ns_l_block_map_entry(n + m)))
      >>- { entries in to_dictionary(entries) }
   }
  )()}
}

// [188]
func ns_l_block_map_entry (_ n: Int) -> YamlParserClosure<(Node, Node)> {
  return {(
    attempt(c_l_block_map_explicit_entry(n)) <|> ns_l_block_map_implicit_entry(n)
  )()}
}

// [189]
func c_l_block_map_explicit_entry (_ n: Int) -> YamlParserClosure<(Node, Node)> {
  return {(
    c_l_block_map_explicit_key(n) >>- { key in
      ( attempt(l_block_map_explicit_value(n)) <|> e_node ) >>- { value in
        create((key, value))
      }
    }
  )()}
}

// [190]
func c_l_block_map_explicit_key (_ n: Int) -> YamlParserClosure<Node> {
  return {(
    char("?") >>> s_l_block_indented(n, .block_out)
  )()}
}

// [191]
func l_block_map_explicit_value (_ n: Int) -> YamlParserClosure<Node> {
  return {(
    s_indent(n) >>> char(":") >>> s_l_block_indented(n, .block_out)
  )()}
}

// [192]
func ns_l_block_map_implicit_entry (_ n: Int) -> YamlParserClosure<(Node, Node)> {
  return {(
    ( attempt(ns_s_block_map_implicit_key) <|> e_node ) >>- { key in
      c_l_block_map_implicit_value(n) >>- { value in
        create((key, value))
      }
    }
  )()}
}

// [193]
func ns_s_block_map_implicit_key () -> YamlParser<Node> {
  return (
    attempt(c_s_implicit_json_key(.block_key)) <|> ns_s_implicit_yaml_key(.block_key)
  )()
}

// [194]
func c_l_block_map_implicit_value (_ n: Int) -> YamlParserClosure<Node> {
  return {(
    char(":")
    >>> ( attempt(s_l_block_node(n, .block_out)) <|> e_node <<< s_l_comments )
  )()}
}

// [195]
func ns_l_compact_mapping (_ n: Int) -> YamlParserClosure<Node> {
  return {(
    ns_l_block_map_entry(n) >>- { entry in
      many(attempt(s_indent(n) >>> ns_l_block_map_entry(n))) >>- { entries in
        to_dictionary(prepend(entry, entries))
      }
    }
  )()}
}

// [196]
func s_l_block_node (_ n: Int, _ c: Context) -> YamlParserClosure<Node> {
  return {(
    attempt(s_l_block_in_block(n, c)) <|> s_l_flow_in_block(n)
  )()}
}

// [197]
func s_l_flow_in_block (_ n: Int) -> YamlParserClosure<Node> {
  return {(
    s_separate(n + 1, .flow_out)
    >>> ns_flow_node(n + 1, .flow_out)
    <<< s_l_comments
  )()}
}

// [198]
func s_l_block_in_block (_ n: Int, _ c: Context) -> YamlParserClosure<Node> {
  return {(
    attempt(s_l_block_scalar(n, c)) <|> s_l_block_collection(n, c)
  )()}
}

// [199]
func s_l_block_scalar (_ n: Int, _ c: Context) -> YamlParserClosure<Node> {
  return {(
    s_separate(n + 1, c)
    >>> option((tag_string, ""), attempt(c_ns_properties(n + 1, c) <<< s_separate(n + 1, c))) >>- { properties in
      let box = Box(properties.anchor)
      return save_anchor(box)
      >>> ( c_l_literal(n) <|> c_l_folded(n) )
      >>- { content in
        create(Node.scalar(content, tag_string))
        >>- apply_properties(properties, box)
      }
    }
  )()}
}

// [200]
func s_l_block_collection (_ n: Int, _ c: Context) -> YamlParserClosure<Node> {
  return {(
    option((tag_non_specific, ""), attempt(s_separate(n + 1, c) >>> c_ns_properties(n + 1, c))) >>- { properties in
      let box = Box(properties.anchor)
      return save_anchor(box)
      >>> s_l_comments
      >>> ( attempt(l_block_sequence(seq_spaces(n, c))) <|> l_block_mapping(n) )
      >>- apply_properties(properties, box)
    }
  )()}
}

// [201]
func seq_spaces (_ n: Int, _ c: Context) -> Int {
  switch c {
  case .block_out: return n - 1
  case .block_in: return n
  default: fatalError("invalid context for seq_spaces")
  }
}
