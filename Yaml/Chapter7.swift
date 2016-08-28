import Parsec
import Foundation

// [104]
func c_ns_alias_node () -> StringParser<String> {
  return ( char("*") >>> ns_anchor_name >>- { anchor in create("*" + anchor) } )()
}

// [105]
func e_scalar () -> StringParser<()> {
  return ( create(()) )()
}

// [106]
func e_node () -> StringParser<()> {
  return e_scalar()
}

// [107]
func nb_double_char () -> StringParser<Character> {
  return ( c_ns_esc_char <|> satisfy(member(nb_double_char_set)) )()
}

let nb_double_char_set: CharacterSet = {
  var allowed = nb_json_set
  allowed.remove(charactersIn: "\\\"")
  return allowed
}()

// [108]
func ns_double_char () -> StringParser<Character> {
  return ( nb_double_char >>- { x in
    if x == " " || x == "\t" {
      return fail("expected non-white-space")
    } else {
      return create(x)
    }
  } )()
}

// [109]
func c_double_quoted (_ n: Int, _ c: Context) -> StringParserClosure<String> {
  return between(char("\""), char("\""), nb_double_text(n, c))
}

// [110]
func nb_double_text (_ n: Int, _ c: Context) -> StringParserClosure<String> {
  switch c {
  case .flow_out, .flow_in: return nb_double_multi_line(n)
  case .block_key, .flow_key: return nb_double_one_line
  default: return fail("invalid use of nb_double_text for context \(c)")
  }
}

// [111]
func nb_double_one_line () -> StringParser<String> {
  return ( many(nb_double_char) >>- { xs in create(String(xs)) } )()
}

// [112]
func s_double_escaped (_ n: Int) -> StringParserClosure<String> {
  return many(s_white) >>- { ws in
    char("\\") >>> b_non_content >>> many(attempt(l_empty(n, .flow_in))) >>- { ls in
      s_flow_line_prefix(n) >>> create(String(ws) + String(ls))
    }
  }
}

// [113]
func s_double_break (_ n: Int) -> StringParserClosure<String> {
  return attempt(s_double_escaped(n)) <|> s_flow_folded(n)
}

// [114]
func nb_ns_double_in_line () -> StringParser<String> {
  return ( many(attempt(many(s_white) >>- { ws in
    ns_double_char >>- { x in create(String(ws) + String(x)) }
  })) >>- { ss in create(ss.joined(separator: "")) } )()
}

// [115]
func s_double_next_line (_ n: Int) -> StringParserClosure<String> {
  return s_double_break(n) >>- { b in
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
}

// [116]
func nb_double_multi_line (_ n: Int) -> StringParserClosure<String> {
  return nb_ns_double_in_line >>- { s in
    ( attempt(s_double_next_line(n)) <|>
      many(s_white) >>- { xs in create(String(xs)) }
    ) >>- { rest in
      create(s + rest)
    }
  }
}

// [117]
func c_quoted_quote () -> StringParser<Character> {
  return ( char("'") <<< char("'") )()
}

// [118]
func nb_single_char () -> StringParser<Character> {
  return ( attempt(c_quoted_quote) <|> satisfy(member(nb_single_char_set)) )()
}

let nb_single_char_set: CharacterSet = {
  var allowed = nb_json_set
  allowed.remove(charactersIn: "'")
  return allowed
}()

// [119]
func ns_single_char () -> StringParser<Character> {
  return ( nb_single_char >>- { x in
    if x == " " || x == "\t" {
      return fail("expected non-white-space")
    } else {
      return create(x)
    }
  } )()
}

// [120]
func c_single_quoted (_ n: Int, _ c: Context) -> StringParserClosure<String> {
  return between(char("'"), char("'"), nb_single_text(n, c))
}

// [121]
func nb_single_text (_ n: Int, _ c: Context) -> StringParserClosure<String> {
  switch c {
  case .flow_out, .flow_in: return nb_single_multi_line(n)
  case .block_key, .flow_key: return nb_single_one_line
  default: return fail("invalid use of nb_single_text for context \(c)")
  }
}

// [122]
func nb_single_one_line () -> StringParser<String> {
  return ( many(nb_single_char) >>- { xs in create(String(xs)) } )()
}

// [123]
func nb_ns_single_in_line () -> StringParser<String> {
  return ( many(attempt(many(s_white) >>- { ws in
    ns_single_char >>- { x in create(String(ws) + String(x)) }
  })) >>- { ss in create(ss.joined(separator: "")) } )()
}

// [124]
func s_single_next_line (_ n: Int) -> StringParserClosure<String> {
  return s_flow_folded(n) >>- { f in
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
}

// [125]
func nb_single_multi_line (_ n: Int) -> StringParserClosure<String> {
  return nb_ns_single_in_line >>- { s in
    ( attempt(s_single_next_line(n)) <|>
      many(s_white) >>- { xs in create(String(xs)) }
    ) >>- { rest in
      create(s + rest)
    }
  }
}

// [126]
func ns_plain_first (_ c: Context) -> StringParserClosure<Character> {
  return satisfy(member(ns_plain_first_set))
    <|> oneOf("?:-") <<< lookAhead(ns_plain_safe(c))
}

let ns_plain_first_set: CharacterSet = {
  var allowed = ns_char_set
  allowed.remove(charactersIn: c_indicator_set_string)
  return allowed
}()

// [127]
func ns_plain_safe (_ c: Context) -> StringParserClosure<Character> {
  switch c {
  case .flow_out, .block_key: return ns_plain_safe_out
  case .flow_in, .flow_key: return ns_plain_safe_in
  default: return fail("invalid use of ns_plain_safe for context \(c)")
  }
}

// [128]
func ns_plain_safe_out () -> StringParser<Character> {
  return satisfy(member(ns_plain_safe_out_set))()
}

let ns_plain_safe_out_set: CharacterSet = {
  return ns_char_set
}()

// [129]
func ns_plain_safe_in () -> StringParser<Character> {
  return satisfy(member(ns_plain_safe_in_set))()
}

let ns_plain_safe_in_set: CharacterSet = {
  var allowed = ns_char_set
  allowed.remove(charactersIn: c_flow_indicator_set_string)
  return allowed
}()

// [130]
func ns_plain_char (_ c: Context) -> StringParserClosure<String> {
  return char(":") >>> ns_plain_safe(c) >>- { x in
    create(":" + String(x))
  } <|> attempt(satisfy(member(ns_char_set)) >>- { x in
    char("#") >>> create(String(x) + "#")
  }) <|> ns_plain_safe(c) >>- { x in
    if x == ":" || x == "#" {
      return fail("expected none of ':#'")
    } else {
      return create(String(x))
    }
  }
}

// [131]
func ns_plain (_ n: Int, _ c: Context) -> StringParserClosure<String> {
  switch c {
  case .flow_out, .flow_in: return ns_plain_multi_line(n, c)
  case .block_key, .flow_key: return ns_plain_one_line(c)
  default: return fail("invalid use of ns_plain for context \(c)")
  }
}

// [132]
func nb_ns_plain_in_line (_ c: Context) -> StringParserClosure<String> {
  return many(attempt(many(s_white) >>- { ws in
    ns_plain_char(c) >>- { x in create(String(ws) + String(x)) }
  })) >>- { ss in create(ss.joined(separator: "")) }
}

// [133]
func ns_plain_one_line (_ c: Context) -> StringParserClosure<String> {
  return ns_plain_first(c) >>- { x in
    nb_ns_plain_in_line(c) >>- { s in
      create(String(x) + s)
    }
  }
}

// [134]
func s_ns_plain_next_line (_ n: Int, _ c: Context) -> StringParserClosure<String> {
  return s_flow_folded(n) >>- { s in
    ns_plain_char(c) >>- { x in
      nb_ns_plain_in_line(c) >>- { l in
        create(s + x + l)
      }
    }
  }
}

// [135]
func ns_plain_multi_line (_ n: Int, _ c: Context) -> StringParserClosure<String> {
  return ns_plain_one_line(c) >>- { l in
    many(attempt(s_ns_plain_next_line(n, c))) >>- { ss in
      create(l + ss.joined(separator: ""))
    }
  }
}
