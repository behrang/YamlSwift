import Parsec
import Foundation

// [63]
func s_indent (_ n: Int) -> YamlParserClosure<()> {
  return {( count(n, s_space) >>> create(()) )()}
}

// [64]
func s_indent_less_than (_ n: Int) -> YamlParserClosure<()> {
  return {(
    ( attempt(count(n, s_space)) <|> many(s_space) ) >>- { xs in
      if (xs.count == n) {
        return fail("expected less than \(n) spaces")
      } else {
        return create(())
      }
    }
  )()}
}

// [65]
func s_indent_less_equal (_ n: Int) -> YamlParserClosure<()> {
  return {(
    ( attempt(count(n + 1, s_space)) <|> many(s_space) ) >>- { xs in
      if (xs.count == n + 1) {
        return fail("expected at most \(n) spaces")
      } else {
        return create(())
      }
    }
  )()}
}

// [66]
func s_separate_in_line () -> YamlParser<()> {
  return ( many1(s_white) >>> create(()) )() // todo: what about 'start of line'?
}

// [67]
func s_line_prefix (_ n: Int, _ c: Context) -> YamlParserClosure<()> {
  return {
    switch c {
    case .block_out, .block_in: return s_block_line_prefix(n)()
    case .flow_out, .flow_in: return s_flow_line_prefix(n)()
    default: return fail("invalid use of s_line_prefix for context \(c)")()
    }
  }
}

// [68]
func s_block_line_prefix (_ n: Int) -> YamlParserClosure<()> {
  return {( s_indent(n) )()}
}

// [69]
func s_flow_line_prefix (_ n: Int) -> YamlParserClosure<()> {
  return {( s_indent(n) >>> optional(s_separate_in_line) )()}
}

// [70]
func l_empty (_ n: Int, _ c: Context) -> YamlParserClosure<Character> {
  return {( ( attempt(s_line_prefix(n, c)) <|> s_indent_less_than(n) ) >>> b_as_line_feed )()}
}

// [71]
func b_l_trimmed (_ n: Int, _ c: Context) -> YamlParserClosure<String> {
  return {(
    b_non_content >>> many1(attempt(l_empty(n, c))) >>- { xs in
      create(String(xs))
    }
  )()}
}

// [72]
func b_as_space () -> YamlParser<String> {
  return ( b_break >>> create(" ") )()
}

// [73]
func b_l_folded (_ n: Int, _ c: Context) -> YamlParserClosure<String> {
  return {( attempt(b_l_trimmed(n, c)) <|> b_as_space )()}
}

// [74]
func s_flow_folded (_ n: Int) -> YamlParserClosure<String> {
  return {(
    optional(s_separate_in_line)
    >>> b_l_folded(n , .flow_in) <<< s_flow_line_prefix(n)
  )()}
}

// [75]
func c_nb_comment_text () -> YamlParser<()> {
  return ( char("#") >>> many(nb_char) >>> create(()) )()
}

// [76]
func b_comment () -> YamlParser<()> {
  return ( b_non_content <|> eof )()
}

// [77]
func s_b_comment () -> YamlParser<()> {
  return ( optional(s_separate_in_line >>> optional(c_nb_comment_text))
    >>> b_comment
  )()
}

// [78]
func l_comment () -> YamlParser<()> {
  return ( s_separate_in_line >>> optional(c_nb_comment_text) >>> b_comment )()
}

// [79]
func s_l_comments () -> YamlParser<()> {
   // todo: what about 'start of line'?
  return ( s_b_comment >>> many(attempt(l_comment)) >>> create(()) )()
}

// [80]
func s_separate (_ n: Int, _ c: Context) -> YamlParserClosure<()> {
  return {
    switch c {
    case .block_out, .block_in, .flow_out, .flow_in: return s_separate_lines(n)()
    case .block_key, .flow_key: return s_separate_in_line()
    }
  }
}

// [81]
func s_separate_lines (_ n: Int) -> YamlParserClosure<()> {
  return {( attempt( s_l_comments >>> s_flow_line_prefix(n) ) <|> s_separate_in_line )()}
}

// [82]
func l_directive () -> YamlParser<(String, [String])> {
  return ( char("%") >>> (
      ns_yaml_directive <|> ns_tag_directive <|> ns_reserved_directive
    ) <<< s_l_comments
  )()
}

// [83]
func ns_reserved_directive () -> YamlParser<(String, [String])> {
  return ( ns_directive_name >>- { name in
    many(attempt(s_separate_in_line >>> ns_directive_parameter)) >>- { params in
      create((name, params))
    }
  } )()
}

// [84]
func ns_directive_name () -> YamlParser<String> {
  return ( many1(ns_char) >>- { xs in create(String(xs)) } )()
}

// [85]
func ns_directive_parameter () -> YamlParser<String> {
  return ( many1(ns_char) >>- { xs in create(String(xs)) } )()
}

// [86]
func ns_yaml_directive () -> YamlParser<(String, [String])> {
  return ( attempt(string("YAML") >>> s_separate_in_line)
    >>> ns_yaml_version >>- { v in create(("YAML", [v])) }
  )()
}

// [87]
func ns_yaml_version () -> YamlParser<String> {
  return ( many1(ns_dec_digit) >>- { major in
    char(".") >>> many1(ns_dec_digit) >>- { minor in
      create(String(major) + "." + String(minor))
    }
  })()
}

// [88]
func ns_tag_directive () -> YamlParser<(String, [String])> {
  return ( attempt(string("TAG") >>> s_separate_in_line)
    >>> c_tag_handle >>- { tag in
      s_separate_in_line >>> ns_tag_prefix >>- { pre in
        create(("TAG", [tag, pre]))
      }
    }
  )()
}

// [89]
func c_tag_handle () -> YamlParser<String> {
  return ( attempt(c_named_tag_handle)
    <|> attempt(c_secondary_tag_handle)
    <|> c_primary_tag_handle
  )()
}

// [90]
func c_primary_tag_handle () -> YamlParser<String> {
  return string("!")()
}

// [91]
func c_secondary_tag_handle () -> YamlParser<String> {
  return string("!!")()
}

// [92]
func c_named_tag_handle () -> YamlParser<String> {
  return ( char("!") >>> many1(ns_word_char) >>- { xs in
    create("!" + String(xs) + "!")
  } <<< char("!") )()
}

// [93]
func ns_tag_prefix () -> YamlParser<String> {
  return ( c_ns_local_tag_prefix <|> ns_global_tag_prefix )()
}

// [94]
func c_ns_local_tag_prefix () -> YamlParser<String> {
  return ( char("!") >>> many(ns_uri_char) >>- { xs in
    create("!" + String(xs))
  } )()
}

// [95]
func ns_global_tag_prefix () -> YamlParser<String> {
  return ( ns_tag_char >>- { x in
    many(ns_uri_char) >>- { xs in
      create(String(x) + String(xs)) }
  } )()
}

// [96]
func c_ns_properties (_ n: Int, _ c: Context) -> YamlParserClosure<(tag: String?, anchor: String?)> {
  return {(
    (
      c_ns_tag_property >>- { tag in
        optionMaybe(attempt(s_separate(n, c) >>> c_ns_anchor_property)) >>- { anchor in
          if let anchor = anchor {
            return create((tag: tag, anchor: anchor))
          } else {
            return create((tag: tag, anchor: nil))
          }
        }
      }
    ) <|> (
      c_ns_anchor_property >>- { anchor in
        optionMaybe(attempt(s_separate(n, c) >>> c_ns_tag_property)) >>- { tag in
          if let tag = tag {
            return create((tag: tag, anchor: anchor))
          } else {
            return create((tag: nil, anchor: anchor))
          }
        }
      }
    )
  )()}
}

// [97]
func c_ns_tag_property () -> YamlParser<String> {
  return ( attempt(c_verbatim_tag) <|> attempt(c_ns_shorthand_tag) <|> c_non_specific_tag )()
}

// [98]
func c_verbatim_tag () -> YamlParser<String> {
  return ( string("!<") >>> many1(ns_uri_char) >>- { xs in
    create("!<" + String(xs) + ">")
  } <<< char(">") )()
}

// [99]
func c_ns_shorthand_tag () -> YamlParser<String> {
  return ( c_tag_handle >>- { tag in
    many1(ns_tag_char) >>- { xs in
      create(tag + String(xs))
    }
  } )()
}

// [100]
func c_non_specific_tag () -> YamlParser<String> {
  return string("!")()
}

// [101]
func c_ns_anchor_property () -> YamlParser<String> {
  return ( char("&") >>> ns_anchor_name )()
}

// [102]
func ns_anchor_char () -> YamlParser<Character> {
  return ( satisfy(member(ns_anchor_char_set)) <?> "allowed anchor character" )()
}

let ns_anchor_char_set: CharacterSet = {
  var allowed = ns_char_set
  allowed.remove(charactersIn: c_flow_indicator_set_string)
  return allowed
}()

// [103]
func ns_anchor_name () -> YamlParser<String> {
  return ( many1(ns_anchor_char) >>- { xs in create(String(xs)) } )()
}
