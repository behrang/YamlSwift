import Parsec
import Foundation

enum Context {
  case block_out
  case block_in
  case flow_out
  case flow_in
  case block_key
  case flow_key
}

func member (_ allowed: CharacterSet) -> (Character) -> Bool {
  return { x in
    String(x).rangeOfCharacter(from: allowed) != nil
  }
}

typealias YamlParser<a> = StringUserParser<a, Schema>
typealias YamlParserClosure<a> = StringUserParserClosure<a, Schema>

// [1]
func c_printable () -> YamlParser<Character> {
  return ( satisfy(member(c_printable_set)) <?> "allowed yaml character" )()
}

let c_printable_set: CharacterSet = {
  var allowed = CharacterSet()
  allowed.insert(charactersIn: "\u{9}\u{a}\u{d}")
  allowed.insert(charactersIn: "\u{20}"..."\u{7e}")
  allowed.insert("\u{85}")
  allowed.insert(charactersIn: "\u{a0}"..."\u{d7fe}")
  allowed.insert("\u{d7ff}") // inserted separately because of a swift bug
  allowed.insert(charactersIn: "\u{e000}"..."\u{fffd}")
  allowed.insert(charactersIn: "\u{10000}"..."\u{10FFFE}")
  allowed.insert("\u{10FFFF}") // inserted separately because of a swift bug
  return allowed
}()

// [2]
func nb_json () -> YamlParser<Character> {
  return ( satisfy(member(nb_json_set)) <?> "allowed json character" )()
}

let nb_json_set: CharacterSet = {
  var allowed = CharacterSet()
  allowed.insert("\u{9}")
  allowed.insert(charactersIn: "\u{20}"..."\u{10FFFE}")
  allowed.insert("\u{10FFFF}") // inserted separately because of a swift bug
  return allowed
}()

// [3]
func c_byte_order_mark () -> YamlParser<()> {
  return ( char("\u{feff}") >>> create(()) <?> "BOM" )()
}

// [4]
func c_sequence_entry () -> YamlParser<Character> {
  return char("-")()
}

// [5]
func c_mapping_key () -> YamlParser<Character> {
  return char("?")()
}

// [6]
func c_mapping_value () -> YamlParser<Character> {
  return char(":")()
}

// [7]
func c_collect_entry () -> YamlParser<Character> {
  return char(",")()
}

// [8]
func c_sequence_start () -> YamlParser<Character> {
  return char("[")()
}

// [9]
func c_sequence_end () -> YamlParser<Character> {
  return char("]")()
}

// [10]
func c_mapping_start () -> YamlParser<Character> {
  return char("{")()
}

// [11]
func c_mapping_end () -> YamlParser<Character> {
  return char("}")()
}

// [12]
func c_comment () -> YamlParser<Character> {
  return char("#")()
}

// [13]
func c_anchor () -> YamlParser<Character> {
  return char("&")()
}

// [14]
func c_alias () -> YamlParser<Character> {
  return char("*")()
}

// [15]
func c_tag () -> YamlParser<Character> {
  return char("!")()
}

// [16]
func c_literal () -> YamlParser<Character> {
  return char("|")()
}

// [17]
func c_folded () -> YamlParser<Character> {
  return char(">")()
}

// [18]
func c_single_quote () -> YamlParser<Character> {
  return char("'")()
}

// [19]
func c_double_quote () -> YamlParser<Character> {
  return char("\"")()
}

// [20]
func c_directive () -> YamlParser<Character> {
  return char("%")()
}

// [21]
func c_reserved () -> YamlParser<Character> {
  return ( oneOf("@`") <?> "reserved indicator character" )()
}

// [22]
func c_indicator () -> YamlParser<Character> {
  return ( satisfy(member(c_indicator_set)) <?> "indicator character" )()
}

let c_indicator_set_string = "-?:,[]{}#&*!|>'\"%@`"
let c_indicator_set: CharacterSet = {
  return CharacterSet(charactersIn: c_indicator_set_string)
}()

// [23]
func c_flow_indicator () -> YamlParser<Character> {
  return ( satisfy(member(c_flow_indicator_set)) <?> "flow indicator character" )()
}

let c_flow_indicator_set_string = ",[]{}"
let c_flow_indicator_set: CharacterSet = {
  return CharacterSet(charactersIn: c_flow_indicator_set_string)
}()

// [24]
func b_line_feed () -> YamlParser<Character> {
  return ( char("\n") <?> "line feed" )()
}

// [25]
func b_carriage_return () -> YamlParser<Character> {
  return ( char("\r") <?> "carriage return" )()
}

// [26]
func b_char () -> YamlParser<Character> {
  return ( b_line_feed <|> b_carriage_return <?> "new-line character" )()
}

// [27]
func nb_char () -> YamlParser<Character> {
  return ( satisfy(member(nb_char_set)) <?> "non-break character" )()
}

let nb_char_set: CharacterSet = {
  var allowed = c_printable_set
  allowed.remove(charactersIn: "\n\r\u{feff}")
  return allowed
}()

// [28]
func b_break () -> YamlParser<Character> {
  return ( char("\r\n") // in Swift, '\r\n' is a single Character
    <|> b_carriage_return
    <|> b_line_feed
  )()
}

// [29]
func b_as_line_feed () -> YamlParser<Character> {
  return ( b_break >>> create("\n") <?> "new-line" )()
}

// [30]
func b_non_content () -> YamlParser<()> {
  return ( b_break >>> create(()) <?> "non-content new-line" )()
}

// [31]
func s_space () -> YamlParser<Character> {
  return char(" ")()
}

// [32]
func s_tab () -> YamlParser<Character> {
  return char("\t")()
}

// [33]
func s_white () -> YamlParser<Character> {
  return ( s_space <|> s_tab <?> "space or tab" )()
}

// [34]
func ns_char () -> YamlParser<Character> {
  return ( satisfy(member(ns_char_set)) <?> "non-space character" )()
}

let ns_char_set: CharacterSet = {
  var allowed = nb_char_set
  allowed.remove(charactersIn: " \t")
  return allowed
}()

// [35]
func ns_dec_digit () -> YamlParser<Character> {
  return ( oneOf("0123456789") <?> "decimal digit" )()
}

// [36]
func ns_hex_digit () -> YamlParser<Character> {
  return ( oneOf("0123456789aAbBcCdDeEfF") <?> "hexadecimal digit" )()
}

// [37]
func ns_ascii_letter () -> YamlParser<Character> {
  return ( satisfy(member(ns_ascii_letter_set)) <?> "ascii letter" )()
}

let ns_ascii_letter_set: CharacterSet = {
  var allowed = CharacterSet()
  allowed.insert(charactersIn: "a"..."z")
  allowed.insert(charactersIn: "A"..."Z")
  return allowed
}()

// [38]
func ns_word_char () -> YamlParser<Character> {
  return ( ns_dec_digit <|> ns_ascii_letter <|> char("-") )()
}

// [39]
func ns_uri_char () -> YamlParser<Character> {
  return ( ns_uri_char_escape
    <|> ns_word_char
    <|> oneOf("#;/?:@&=+$,_.!~*'()[]")
    <?> "uir char"
  )()
}

func ns_uri_char_escape () -> YamlParser<Character> {
  return ( char("%") >>> ns_hex_digit >>- { d1 in
      ns_hex_digit >>- { d2 in
        to_character([d1, d2])
      }
    } <?> "uri escape sequence"
  )()
}

func to_character (_ hds: [Character]) -> YamlParserClosure<Character> {
  return {
    let code = String(hds)
    let i = Int(code, radix: 16)!
    return create(Character(UnicodeScalar(i)!))()
  }
}

// [40]
func ns_tag_char () -> YamlParser<Character> {
  return ( ns_uri_char_escape
    <|> ns_word_char
    <|> oneOf("#;/?:@&=+$_.~*'()")
    <?> "tag char"
  )()
}

// [41]
func c_escape () -> YamlParser<Character> {
  return char("\\")()
}

// [42]
func ns_esc_null () -> YamlParser<Character> {
  return ( char("0") >>> create("\u{0}") )()
}

// [43]
func ns_esc_bell () -> YamlParser<Character> {
  return ( char("a") >>> create("\u{7}") )()
}

// [44]
func ns_esc_backspace () -> YamlParser<Character> {
  return ( char("b") >>> create("\u{8}") )()
}

// [45]
func ns_esc_horizontal_tab () -> YamlParser<Character> {
  return ( oneOf("t\u{9}") >>> create("\u{9}") )()
}

// [46]
func ns_esc_line_feed () -> YamlParser<Character> {
  return ( char("n") >>> create("\u{a}") )()
}

// [47]
func ns_esc_vertical_tab () -> YamlParser<Character> {
  return ( char("v") >>> create("\u{b}") )()
}

// [48]
func ns_esc_form_feed () -> YamlParser<Character> {
  return ( char("f") >>> create("\u{c}") )()
}

// [49]
func ns_esc_carriage_return () -> YamlParser<Character> {
  return ( char("r") >>> create("\u{d}") )()
}

// [50]
func ns_esc_escape () -> YamlParser<Character> {
  return ( char("e") >>> create("\u{1b}") )()
}

// [51]
func ns_esc_space () -> YamlParser<Character> {
  return ( char(" ") >>> create("\u{20}") )()
}

// [52]
func ns_esc_double_quote () -> YamlParser<Character> {
  return ( char("\"") >>> create("\u{22}") )()
}

// [53]
func ns_esc_slash () -> YamlParser<Character> {
  return ( char("/") >>> create("\u{2f}") )()
}

// [54]
func ns_esc_backslash () -> YamlParser<Character> {
  return ( char("\\") >>> create("\u{5c}") )()
}

// [55]
func ns_esc_next_line () -> YamlParser<Character> {
  return ( char("N") >>> create("\u{85}") )()
}

// [56]
func ns_esc_non_breaking_space () -> YamlParser<Character> {
  return ( char("_") >>> create("\u{a0}") )()
}

// [57]
func ns_esc_line_separator () -> YamlParser<Character> {
  return ( char("L") >>> create("\u{2028}") )()
}

// [58]
func ns_esc_paragraph_separator () -> YamlParser<Character> {
  return ( char("P") >>> create("\u{2029}") )()
}

// [59]
func ns_esc_8_bit () -> YamlParser<Character> {
  return ( char("x") >>> count(2, ns_hex_digit) >>- to_character )()
}

// [60]
func ns_esc_16_bit () -> YamlParser<Character> {
  return ( char("u") >>> count(4, ns_hex_digit) >>- to_character )()
}

// [61]
func ns_esc_32_bit () -> YamlParser<Character> {
  return ( char("U") >>> count(8, ns_hex_digit) >>- to_character )()
}

// [62]
func c_ns_esc_char () -> YamlParser<Character> {
  return ( char("\\") >>> (
        ns_esc_null <|> ns_esc_bell <|> ns_esc_backspace
    <|> ns_esc_horizontal_tab <|> ns_esc_line_feed
    <|> ns_esc_vertical_tab <|> ns_esc_form_feed
    <|> ns_esc_carriage_return <|> ns_esc_escape <|> ns_esc_space
    <|> ns_esc_double_quote <|> ns_esc_slash <|> ns_esc_backslash
    <|> ns_esc_next_line <|> ns_esc_non_breaking_space
    <|> ns_esc_line_separator <|> ns_esc_paragraph_separator
    <|> ns_esc_8_bit <|> ns_esc_16_bit <|> ns_esc_32_bit
  ) )()
}
