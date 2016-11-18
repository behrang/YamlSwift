import Parsec
import Foundation

func prepend<a> (_ x: a, _ xs: [a]) -> [a] {
  var r = [x]
  r.append(contentsOf: xs)
  return r
}

func put<a> (_ x: (a, a), _ xs: [a: a]) -> YamlParserClosure<[a: a]> {
  var r = xs
  if r[x.0] != nil {
    return unexpected("found duplicate flow mapping key: \(x.0)")
  }
  r[x.0] = x.1
  return create(r)
}

// [104]
func c_ns_alias_node () -> YamlParser<Node> {
  return (
    char("*")
    >>> ns_anchor_name
    >>- { anchor in
      getState >>- { state in
        if let box = state.anchors[anchor] {
          return create(.alias(box))
        } else {
          return unexpected("unidentified alias: \(anchor)")
        }
      }
    }
  )()
}

// [105]
func e_scalar () -> YamlParser<()> {
  return ( create(()) )()
}

// [106]
func e_node () -> YamlParser<Node> {
  return ( e_scalar >>> create(.scalar("", tag_null)) )()
}

// [107]
func nb_double_char () -> YamlParser<Character> {
  return ( c_ns_esc_char <|> satisfy(member(nb_double_char_set)) )()
}

let nb_double_char_set: CharacterSet = {
  var allowed = nb_json_set
  allowed.remove(charactersIn: "\\\"")
  return allowed
}()

// [108]
func ns_double_char () -> YamlParser<Character> {
  return ( notFollowedBy(s_white) >>> nb_double_char )()
}

// [109]
func c_double_quoted (_ n: Int, _ c: Context) -> YamlParserClosure<Node> {
  return {(
    between(char("\""), char("\""), nb_double_text(n, c)) >>- { c in
      create(.scalar(c, tag_string))
    }
  )()}
}

// [110]
func nb_double_text (_ n: Int, _ c: Context) -> YamlParserClosure<String> {
  return {
    switch c {
    case .flow_out, .flow_in: return nb_double_multi_line(n)()
    case .block_key, .flow_key: return nb_double_one_line()
    default: return fail("invalid use of nb_double_text for context \(c)")()
    }
  }
}

// [111]
func nb_double_one_line () -> YamlParser<String> {
  return ( many(nb_double_char) >>- { xs in create(String(xs)) } )()
}

// [112]
func s_double_escaped (_ n: Int) -> YamlParserClosure<String> {
  return {(
    many(s_white) >>- { ws in
      char("\\") >>> b_non_content >>> many(attempt(l_empty(n, .flow_in))) >>- { ls in
        s_flow_line_prefix(n) >>> create(String(ws) + String(ls))
      }
    }
  )()}
}

// [113]
func s_double_break (_ n: Int) -> YamlParserClosure<String> {
  return {( attempt(s_double_escaped(n)) <|> s_flow_folded(n) )()}
}

// [114]
func nb_ns_double_in_line () -> YamlParser<String> {
  return ( many(attempt(many(s_white) >>- { ws in
    ns_double_char >>- { x in create(String(ws) + String(x)) }
  })) >>- { ss in create(ss.joined(separator: "")) } )()
}

// [115]
func s_double_next_line (_ n: Int) -> YamlParserClosure<String> {
  return {(
    s_double_break(n) >>- { b in
      (notFollowedBy(c_forbidden) <?> "no document markers") >>>
      optionMaybe(attempt(ns_double_char >>- { x in
        nb_ns_double_in_line >>- { s in
          ( attempt(s_double_next_line(n)) <|>
            many(s_white) >>- { xs in create(String(xs)) }
          ) >>- { rest in
            create(String(x) + s + rest)
          }
        }
      })) >>- { m in
        if let m = m {
          return create(b + m)
        } else {
          return create(b)
        }
      }
    }
  )()}
}

// [116]
func nb_double_multi_line (_ n: Int) -> YamlParserClosure<String> {
  return {(
    nb_ns_double_in_line >>- { s in
      ( attempt(s_double_next_line(n)) <|>
        many(s_white) >>- { xs in create(String(xs)) }
      ) >>- { rest in
        create(s + rest)
      }
    }
  )()}
}

// [117]
func c_quoted_quote () -> YamlParser<Character> {
  return ( char("'") <<< char("'") )()
}

// [118]
func nb_single_char () -> YamlParser<Character> {
  return ( attempt(c_quoted_quote) <|> satisfy(member(nb_single_char_set)) )()
}

let nb_single_char_set: CharacterSet = {
  var allowed = nb_json_set
  allowed.remove(charactersIn: "'")
  return allowed
}()

// [119]
func ns_single_char () -> YamlParser<Character> {
  return ( nb_single_char >>- { x in
    if x == " " || x == "\t" {
      return fail("expected non-white-space")
    } else {
      return create(x)
    }
  } )()
}

// [120]
func c_single_quoted (_ n: Int, _ c: Context) -> YamlParserClosure<Node> {
  return {(
    between(char("'"), char("'"), nb_single_text(n, c)) >>- { c in
      create(.scalar(c, tag_string))
    }
  )()}
}

// [121]
func nb_single_text (_ n: Int, _ c: Context) -> YamlParserClosure<String> {
  return {
    switch c {
    case .flow_out, .flow_in: return nb_single_multi_line(n)()
    case .block_key, .flow_key: return nb_single_one_line()
    default: return fail("invalid use of nb_single_text for context \(c)")()
    }
  }
}

// [122]
func nb_single_one_line () -> YamlParser<String> {
  return ( many(nb_single_char) >>- { xs in create(String(xs)) } )()
}

// [123]
func nb_ns_single_in_line () -> YamlParser<String> {
  return ( many(attempt(many(s_white) >>- { ws in
    ns_single_char >>- { x in create(String(ws) + String(x)) }
  })) >>- { ss in create(ss.joined(separator: "")) } )()
}

// [124]
func s_single_next_line (_ n: Int) -> YamlParserClosure<String> {
  return {(
    s_flow_folded(n) >>- { f in
      (notFollowedBy(c_forbidden) <?> "no document markers") >>>
      optionMaybe(attempt(ns_single_char >>- { x in
        nb_ns_single_in_line >>- { s in
          ( attempt(s_single_next_line(n)) <|>
            many(s_white) >>- { xs in create(String(xs)) }
          ) >>- { rest in
            create(String(x) + s + rest)
          }
        }
      })) >>- { m in
        if let m = m {
          return create(f + m)
        } else {
          return create(f)
        }
      }
    }
  )()}
}

// [125]
func nb_single_multi_line (_ n: Int) -> YamlParserClosure<String> {
  return {(
    nb_ns_single_in_line >>- { s in
      ( attempt(s_single_next_line(n)) <|>
        many(s_white) >>- { xs in create(String(xs)) }
      ) >>- { rest in
        create(s + rest)
      }
    }
  )()}
}

// [126]
func ns_plain_first (_ c: Context) -> YamlParserClosure<Character> {
  return {(
    satisfy(member(ns_plain_first_set))
    <|> oneOf("?:-") <<< lookAhead(ns_plain_safe(c))
  )()}
}

let ns_plain_first_set: CharacterSet = {
  var allowed = ns_char_set
  allowed.remove(charactersIn: c_indicator_set_string)
  return allowed
}()

// [127]
func ns_plain_safe (_ c: Context) -> YamlParserClosure<Character> {
  return {
    switch c {
    case .flow_out, .block_key: return ns_plain_safe_out()
    case .flow_in, .flow_key: return ns_plain_safe_in()
    default: return fail("invalid use of ns_plain_safe for context \(c)")()
    }
  }
}

// [128]
func ns_plain_safe_out () -> YamlParser<Character> {
  return satisfy(member(ns_plain_safe_out_set))()
}

let ns_plain_safe_out_set: CharacterSet = {
  return ns_char_set
}()

// [129]
func ns_plain_safe_in () -> YamlParser<Character> {
  return satisfy(member(ns_plain_safe_in_set))()
}

let ns_plain_safe_in_set: CharacterSet = {
  var allowed = ns_char_set
  allowed.remove(charactersIn: c_flow_indicator_set_string)
  return allowed
}()

// [130]
func ns_plain_char (_ c: Context) -> YamlParserClosure<Character> {
  return {(
    lookAhead(noneOf(":#")) >>> ns_plain_safe(c)
    <|> attempt(char(":") <<< lookAhead(ns_plain_safe(c)))
  )()}
}

// [131]
func ns_plain (_ n: Int, _ c: Context) -> YamlParserClosure<String> {
  return {
    switch c {
    case .flow_out, .flow_in: return ns_plain_multi_line(n, c)()
    case .block_key, .flow_key: return ns_plain_one_line(c)()
    default: return fail("invalid use of ns_plain for context \(c)")()
    }
  }
}

// [132]
func nb_ns_plain_in_line (_ c: Context) -> YamlParserClosure<String> {
  return {(
    many(attempt(many(s_white) >>- { ws in
      ns_plain_char(c) >>- { x in create(String(ws) + String(x)) }
      <|> char("#") >>- { _ in
        if ws.count == 0 {
          return create("#")
        } else {
          return fail("comment character")
        }
      }
    })) >>- { ss in create(ss.joined(separator: "")) }
  )()}
}

// [133]
func ns_plain_one_line (_ c: Context) -> YamlParserClosure<String> {
  return {(
    (notFollowedBy(c_forbidden) <?> "no document markers") >>>
    ns_plain_first(c) >>- { x in
      nb_ns_plain_in_line(c) >>- { s in
        create(String(x) + s)
      }
    }
  )()}
}

// [134]
func s_ns_plain_next_line (_ n: Int, _ c: Context) -> YamlParserClosure<String> {
  return {(
    s_flow_folded(n) >>- { s in
      (notFollowedBy(c_forbidden) <?> "no document markers") >>>
      ns_plain_char(c) >>- { x in
        nb_ns_plain_in_line(c) >>- { l in
          create(s + String(x) + l)
        }
      }
    }
  )()}
}

// [135]
func ns_plain_multi_line (_ n: Int, _ c: Context) -> YamlParserClosure<String> {
  return {(
    ns_plain_one_line(c) >>- { l in
      many(attempt(s_ns_plain_next_line(n, c))) >>- { ss in
        create(l + ss.joined(separator: ""))
      }
    }
  )()}
}

// [136]
func in_flow (_ c: Context) -> Context {
  switch c {
  case .flow_out, .flow_in: return .flow_in
  case .block_key, .flow_key: return .flow_key
  default: return c
  }
}

// [137]
func c_flow_sequence (_ n: Int, _ c: Context) -> YamlParserClosure<Node> {
  return {(
    char("[")
    >>> optional(attempt(s_separate(n, c)))
    >>> option([], attempt(ns_s_flow_seq_entries(n, in_flow(c))))
    <<< char("]")
    >>- { entries in create(.sequence(entries, tag_sequence)) }
  )()}
}

// [138]
func ns_s_flow_seq_entries (_ n: Int, _ c: Context) -> YamlParserClosure<[Node]> {
  return {(
    ns_flow_seq_entry(n, c) >>- { entry in
      optional(attempt(s_separate(n, c)))
      >>> option([], attempt(char(",")
        >>> optional(attempt(s_separate(n, c)))
        >>> option([], attempt(ns_s_flow_seq_entries(n, c)))
      )) >>- { entries in create(prepend(entry, entries)) }
    }
  )()}
}

// [139]
func ns_flow_seq_entry (_ n: Int, _ c: Context) -> YamlParserClosure<Node> {
  return {( attempt(ns_flow_pair(n, c)) <|> ns_flow_node(n, c) )()}
}

// [140]
func c_flow_mapping (_ n: Int, _ c: Context) -> YamlParserClosure<Node> {
  return {(
    char("{")
    >>> optional(attempt(s_separate(n, c)))
    >>> option([:], attempt(ns_s_flow_map_entries(n, in_flow(c))))
    <<< char("}")
    >>- { entries in create(.mapping(entries, tag_mapping)) }
  )()}
}

// [141]
func ns_s_flow_map_entries (_ n: Int, _ c: Context) -> YamlParserClosure<[Node: Node]> {
  return {(
    ns_flow_map_entry(n, c) >>- { entry in
      optional(attempt(s_separate(n, c)))
      >>> option([:], attempt(char(",")
        >>> optional(attempt(s_separate(n, c)))
        >>> option([:], attempt(ns_s_flow_map_entries(n, c)))
      )) >>- { entries in put(entry, entries) }
    }
  )()}
}

// [142]
func ns_flow_map_entry (_ n: Int, _ c: Context) -> YamlParserClosure<(Node, Node)> {
  return {(
    attempt(
      char("?")
      >>> s_separate(n, c)
      >>> ns_flow_map_explicit_entry(n, c)
    ) <|> ns_flow_map_implicit_entry(n, c)
  )()}
}

// [143]
func ns_flow_map_explicit_entry (_ n: Int, _ c: Context) -> YamlParserClosure<(Node, Node)> {
  return {(
    attempt(ns_flow_map_implicit_entry(n, c))
    <|> e_node >>- { key in
      e_node >>- { value in
        create((key, value))
      }
    }
  )()}
}

// [144]
func ns_flow_map_implicit_entry (_ n: Int, _ c: Context) -> YamlParserClosure<(Node, Node)> {
  return {(
    attempt(ns_flow_map_yaml_key_entry(n, c))
    <|> attempt(c_ns_flow_map_empty_key_entry(n, c))
    <|> c_ns_flow_map_json_key_entry(n, c)
  )()}
}

// [145]
func ns_flow_map_yaml_key_entry (_ n: Int, _ c: Context) -> YamlParserClosure<(Node, Node)> {
  return {(
    ns_flow_yaml_node(n, c) >>- { key in
      ( optional(attempt(s_separate(n, c)))
        >>> attempt(c_ns_flow_map_separate_value(n, c))
        <|> e_node
      ) >>- { value in
        create((key, value))
      }
    }
  )()}
}

// [146]
func c_ns_flow_map_empty_key_entry (_ n: Int, _ c: Context) -> YamlParserClosure<(Node, Node)> {
  return {(
    e_node >>- { key in
      c_ns_flow_map_separate_value(n, c) >>- { value in
        create((key, value))
      }
    }
  )()}
}

// [147]
func c_ns_flow_map_separate_value (_ n: Int, _ c: Context) -> YamlParserClosure<Node> {
  return {(
    char(":")
    <<< notFollowedBy(ns_plain_safe(c))
    >>> (
      attempt(s_separate(n, c) >>> ns_flow_node(n, c))
      <|> e_node
    ) >>- { value in create(value) }
  )()}
}

// [148]
func c_ns_flow_map_json_key_entry (_ n: Int, _ c: Context) -> YamlParserClosure<(Node, Node)> {
  return {(
    c_flow_json_node(n, c) >>- { key in
      ( attempt(optional(attempt(s_separate(n, c))) >>> c_ns_flow_map_adjacent_value(n, c))
        <|> e_node
      ) >>- { value in
        create((key, value))
      }
    }
  )()}
}

// [149]
func c_ns_flow_map_adjacent_value (_ n: Int, _ c: Context) -> YamlParserClosure<Node> {
  return {(
    char(":")
    >>> (
      attempt(optional(attempt(s_separate(n, c))) >>> ns_flow_node(n, c))
      <|> e_node
    ) >>- { value in create(value) }
  )()}
}

// [150]
func ns_flow_pair (_ n: Int, _ c: Context) -> YamlParserClosure<Node> {
  return {(
    (
      attempt(
        char("?")
        >>> s_separate(n, c)
        >>> ns_flow_map_explicit_entry(n, c)
      ) <|> ns_flow_pair_entry(n, c)
    ) >>- { pair in create(.mapping([pair.0: pair.1], tag_mapping)) }
  )()}
}

// [151]
func ns_flow_pair_entry (_ n: Int, _ c: Context) -> YamlParserClosure<(Node, Node)> {
  return {(
    attempt(ns_flow_pair_yaml_key_entry(n, c))
    <|> attempt(c_ns_flow_map_empty_key_entry(n, c))
    <|> c_ns_flow_pair_json_key_entry(n, c)
  )()}
}

// [152]
func ns_flow_pair_yaml_key_entry (_ n: Int, _ c: Context) -> YamlParserClosure<(Node, Node)> {
  return {(
    ns_s_implicit_yaml_key(.flow_key) >>- { key in
      c_ns_flow_map_separate_value(n, c) >>- { value in
        create((key, value))
      }
    }
  )()}
}

// [153]
func c_ns_flow_pair_json_key_entry (_ n: Int, _ c: Context) -> YamlParserClosure<(Node, Node)> {
  return {(
    c_s_implicit_json_key(.flow_key) >>- { key in
      c_ns_flow_map_adjacent_value(n, c) >>- { value in
        create((key, value))
      }
    }
  )()}
}

// [154]
func ns_s_implicit_yaml_key (_ c: Context) -> YamlParserClosure<Node> {
  return {(
    same_line_implicit_key(1024, c)
    >>> ns_flow_yaml_node(-1, c)
    <<< optional(attempt(s_separate_in_line))
  )()}
}

func same_line_implicit_key (_ n: Int, _ c: Context) -> YamlParserClosure<()> {
  let msg = "key indicator not found on the same line in 1024 characters"
  return {(
    getInput >>- { input in
      let s = String(input)
      if let range = s.range(of: "^.{0,1025}", options: .regularExpression) {
        let sub = s[range]
        switch c {
        case .flow_out, .block_key:
          let regex = ":([^\u{21}-\u{7e}\u{85}\u{a0}-\u{d7ff}" +
            "\u{e000}-\u{fefe}\u{ff00}-\u{fffd}\u{10000}-\u{10ffff}]|$)"
          if match(sub, regex) {
            return create(())
          } else {
            return fail(msg)
          }
        case .flow_in, .flow_key:
          let regex = ":([^\u{21}-\u{2b}\u{2d}-\u{5a}\u{5c}" +
            "\u{5e}-\u{7a}\u{7c}\u{7e}\u{85}\u{a0}-\u{d7ff}" +
            "\u{e000}-\u{fefe}\u{ff00}-\u{fffd}\u{10000}-\u{10ffff}]|$)"
          if match(sub, regex) {
            return create(())
          } else {
            return fail(msg)
          }
        default: return fail("invalid use of ns_plain_safe for context \(c)")
        }
      } else {
        return fail(msg)
      }
    }
  )()}
}

// [155]
func c_s_implicit_json_key (_ c: Context) -> YamlParserClosure<Node> {
  return {(
    same_line_implicit_key(1024, c)
    >>> c_flow_json_node(-1, c)
    <<< optional(attempt(s_separate_in_line))
  )()}
}

// [156]
func ns_flow_yaml_content (_ n: Int, _ c: Context) -> YamlParserClosure<Node> {
  return {( ns_plain(n, c) >>- { s in create(.scalar(s, tag_unknown)) } )()}
}

// [157]
func c_flow_json_content (_ n: Int, _ c: Context) -> YamlParserClosure<Node> {
  return {(
    attempt(c_flow_sequence(n, c))
    <|> attempt(c_flow_mapping(n, c))
    <|> attempt(c_single_quoted(n, c))
    <|> c_double_quoted(n, c)
  )()}
}

// [158]
func ns_flow_content (_ n: Int, _ c: Context) -> YamlParserClosure<Node> {
  return {(
    attempt(ns_flow_yaml_content(n, c))
    <|> c_flow_json_content(n, c)
  )()}
}

// [159]
func ns_flow_yaml_node (_ n: Int, _ c: Context) -> YamlParserClosure<Node> {
  return {(
    attempt(c_ns_alias_node)
    <|> attempt(ns_flow_yaml_content(n, c))
    <|> c_ns_properties(n, c) >>- { properties in
      let box = Box(properties.anchor)
      return save_anchor(box)
      >>> ( s_separate(n, c) >>> ns_flow_yaml_content(n, c) <|> e_node )
      >>- apply_properties(properties, box)
    }
  )()}
}

// [160]
func c_flow_json_node (_ n: Int, _ c: Context) -> YamlParserClosure<Node> {
  return {(
    option((tag_unknown, ""), attempt(c_ns_properties(n, c) <<< s_separate(n, c))) >>- { properties in
      let box = Box(properties.anchor)
      return save_anchor(box)
      >>> c_flow_json_content(n, c)
      >>- apply_properties(properties, box)
    }
  )()}
}

// [161]
func ns_flow_node (_ n: Int, _ c: Context) -> YamlParserClosure<Node> {
  return {(
    attempt(c_ns_alias_node)
    <|> attempt(ns_flow_content(n, c))
    <|> c_ns_properties(n, c) >>- { properties in
      let box = Box(properties.anchor)
      return save_anchor(box)
      >>> ( attempt(s_separate(n, c) >>> ns_flow_content(n, c)) <|> e_node )
      >>- apply_properties(properties, box)
    }
  )()}
}

func apply_properties (_ properties: Properties, _ box: Box) -> (Node) -> YamlParserClosure<Node> {
  return { node in
    getState >>- { state in
      switch node {
      case .scalar(let c, _):
        box.node = .scalar(c, properties.tag)
      case .sequence(let c, _):
        box.node = .sequence(c, properties.tag)
      case .mapping(let c, _):
        box.node = .mapping(c, properties.tag)
      default: fatalError("alias nodes don't have properties")
      }
      return create(box.node!)
    }
  }
}

func save_anchor (_ box: Box) -> YamlParserClosure<()> {
  return modifyState({ state in
    var modified = state
    modified.anchors[box.anchor] = box
    return modified
  })
}
