import XCTest
import Parsec

@testable
import Yaml

class Chapter5: XCTestCase {

  func test_001_c_printable () {
    left(c_printable, "\u{8}z")
    right(c_printable, "\u{9}z", "\u{9}")
    right(c_printable, "Behrang", "B")
  }

  func test_002_nb_json () {
    left(nb_json, "\u{a}z")
    right(nb_json, "\u{9}z", "\u{9}")
    right(nb_json, "Behrang", "B")
  }

  func test_003_c_byte_order_mark () {
    left(c_byte_order_mark, "\u{fefe}z")
    right(c_byte_order_mark, "\u{feff}z")
  }

  func test_004_c_sequence_entry () {
    left(c_sequence_entry, "?z")
    right(c_sequence_entry, "-z", "-")
  }

  func test_005_c_mapping_key () {
    left(c_mapping_key, "-z")
    right(c_mapping_key, "?z", "?")
  }

  func test_006_c_mapping_value () {
    left(c_mapping_value, "?z")
    right(c_mapping_value, ":z", ":")
  }

  func test_007_c_collect_entry () {
    left(c_collect_entry, "-z")
    right(c_collect_entry, ",z", ",")
  }

  func test_008_c_sequence_start () {
    left(c_sequence_start, "]z")
    right(c_sequence_start, "[z", "[")
  }

  func test_009_c_sequence_end () {
    left(c_sequence_end, "[z")
    right(c_sequence_end, "]z", "]")
  }

  func test_010_c_mapping_start () {
    left(c_mapping_start, "}z")
    right(c_mapping_start, "{z", "{")
  }

  func test_011_c_mapping_end () {
    left(c_mapping_end, "{z")
    right(c_mapping_end, "}z", "}")
  }

  func test_012_c_comment () {
    left(c_comment, "/z")
    right(c_comment, "#z", "#")
  }

  func test_013_c_anchor () {
    left(c_anchor, "*z")
    right(c_anchor, "&z", "&")
  }

  func test_014_c_alias () {
    left(c_alias, "&z")
    right(c_alias, "*z", "*")
  }

  func test_015_c_tag () {
    left(c_tag, "%z")
    right(c_tag, "!z", "!")
  }

  func test_016_c_literal () {
    left(c_literal, ">z")
    right(c_literal, "|z", "|")
  }

  func test_017_c_folded () {
    left(c_folded, "|z")
    right(c_folded, ">z", ">")
  }

  func test_018_c_single_quote () {
    left(c_single_quote, "\"z")
    right(c_single_quote, "'z", "'")
  }

  func test_019_c_double_quote () {
    left(c_double_quote, "'z")
    right(c_double_quote, "\"z", "\"")
  }

  func test_020_c_directive () {
    left(c_directive, "!z")
    right(c_directive, "%z", "%")
  }

  func test_021_c_reserved () {
    left(c_reserved, "^z")
    right(c_reserved, "@z", "@")
    right(c_reserved, "`z", "`")
  }

  func test_022_c_indicator () {
    left(c_indicator, "^z")
    right(c_indicator, "-z", "-")
    right(c_indicator, ">z", ">")
  }

  func test_023_c_flow_indicator () {
    left(c_flow_indicator, "-z")
    right(c_flow_indicator, "[z", "[")
    right(c_flow_indicator, "]z", "]")
    right(c_flow_indicator, ",z", ",")
  }

  func test_024_b_line_feed () {
    left(b_line_feed, "\rz")
    right(b_line_feed, "\nz", "\n")
    right(b_line_feed, "\n\rz", "\n")
    right(b_line_feed, "\n\nz", "\n")
  }

  func test_025_b_carriage_return () {
    left(b_carriage_return, "\nz")
    left(b_carriage_return, "\r\nz")
    right(b_carriage_return, "\rz", "\r")
  }

  func test_026_b_char () {
    left(b_char, "\tz")
    right(b_char, "\rz", "\r")
    right(b_char, "\nz", "\n")
  }

  func test_027_nb_char () {
    left(nb_char, "\rz")
    left(nb_char, "\nz")
    left(nb_char, "\u{feff}z")
    right(nb_char, "\tz", "\t")
  }

  func test_028_b_break () {
    left(b_break, "\tz")
    right(b_break, "\r\nz", "\r\n")
    right(b_break, "\rz", "\r")
    right(b_break, "\nz", "\n")
    right(b_break, "\n\rz", "\n")
  }

  func test_029_b_as_line_feed () {
    left(b_as_line_feed, "\tz")
    right(b_as_line_feed, "\r\nz", "\n")
    right(b_as_line_feed, "\rz", "\n")
    right(b_as_line_feed, "\nz", "\n")
    right(b_as_line_feed, "\n\rz", "\n")
  }

  func test_030_b_non_content () {
    left(b_non_content, "\tz")
    right(b_non_content, "\r\nz")
    right(b_non_content, "\rz")
    right(b_non_content, "\nz")
    right(b_non_content, "\n\rz")
  }

  func test_031_s_space () {
    left(s_space, "\tz")
    right(s_space, " z", " ")
  }

  func test_032_s_tab () {
    left(s_tab, " z")
    right(s_tab, "\tz", "\t")
  }

  func test_033_s_white () {
    left(s_white, "\nz")
    right(s_white, "\tz", "\t")
    right(s_white, " z", " ")
  }

  func test_034_ns_char () {
    left(ns_char, "\nz")
    left(ns_char, "\rz")
    left(ns_char, "\r\nz")
    left(ns_char, "\tz")
    left(ns_char, " z")
    right(ns_char, "-z", "-")
    right(ns_char, "Bz", "B")
  }

  func test_035_ns_dec_digit () {
    left(ns_dec_digit, "Bz")
    left(ns_dec_digit, "-z")
    left(ns_dec_digit, "\nz")
    left(ns_dec_digit, " z")
    left(ns_dec_digit, "۱z")
    right(ns_dec_digit, "1z", "1")
  }

  func test_036_ns_hex_digit () {
    left(ns_hex_digit, "-z")
    left(ns_hex_digit, "\nz")
    left(ns_hex_digit, " z")
    left(ns_hex_digit, "۱z")
    left(ns_hex_digit, "gz")
    right(ns_hex_digit, "1z", "1")
    right(ns_hex_digit, "Bz", "B")
    right(ns_hex_digit, "fz", "f")
  }

  func test_037_ns_ascii_letter () {
    left(ns_ascii_letter, "-z")
    left(ns_ascii_letter, "\nz")
    left(ns_ascii_letter, " z")
    left(ns_ascii_letter, "۱z")
    left(ns_ascii_letter, "1z")
    right(ns_ascii_letter, "Bz", "B")
    right(ns_ascii_letter, "fz", "f")
  }

  func test_038_ns_word_char () {
    left(ns_word_char, "\nz")
    left(ns_word_char, " z")
    left(ns_word_char, "_z")
    left(ns_word_char, "۱z")
    right(ns_word_char, "1z", "1")
    right(ns_word_char, "Bz", "B")
    right(ns_word_char, "fz", "f")
    right(ns_word_char, "-z", "-")
  }

  func test_039_ns_uri_char () {
    left(ns_uri_char, "%FGz")
    left(ns_uri_char, " z")
    left(ns_uri_char, "\nz")
    left(ns_uri_char, "^z")
    right(ns_uri_char, ",z", ",")
    right(ns_uri_char, "!z", "!")
    right(ns_uri_char, "[z", "[")
    right(ns_uri_char, "%62z", "b")
    right(ns_uri_char, "Bz", "B")
    right(ns_uri_char, "/z", "/")
    right(ns_uri_char, "-z", "-")
  }

  func test_040_ns_tag_char () {
    left(ns_tag_char, "%FGz")
    left(ns_tag_char, " z")
    left(ns_tag_char, "\nz")
    left(ns_tag_char, "^z")
    left(ns_tag_char, ",z")
    left(ns_tag_char, "!z")
    left(ns_tag_char, "[z")
    right(ns_tag_char, "%62", "b")
    right(ns_tag_char, "Bz", "B")
    right(ns_tag_char, "/z", "/")
    right(ns_tag_char, "-z", "-")
  }

  func test_062_c_ns_esc_char () {
    left(c_ns_esc_char, "\\")
    left(c_ns_esc_char, "\\1z")
    right(c_ns_esc_char, "\\0z", "\u{0}")
    right(c_ns_esc_char, "\\az", "\u{7}")
    right(c_ns_esc_char, "\\tz", "\t")
    right(c_ns_esc_char, "\\\u{9}z", "\t")
    right(c_ns_esc_char, "\\nz", "\n")
    right(c_ns_esc_char, "\\vz", "\u{b}")
    right(c_ns_esc_char, "\\fz", "\u{c}")
    right(c_ns_esc_char, "\\rz", "\u{d}")
    right(c_ns_esc_char, "\\ez", "\u{1b}")
    right(c_ns_esc_char, "\\ z", " ")
    right(c_ns_esc_char, "\\\"z", "\"")
    right(c_ns_esc_char, "\\/z", "/")
    right(c_ns_esc_char, "\\\\z", "\\")
    right(c_ns_esc_char, "\\Nz", "\u{85}")
    right(c_ns_esc_char, "\\_z", "\u{a0}")
    right(c_ns_esc_char, "\\Lz", "\u{2028}")
    right(c_ns_esc_char, "\\Pz", "\u{2029}")
    right(c_ns_esc_char, "\\xa0z", "\u{a0}")
    right(c_ns_esc_char, "\\u2028z", "\u{2028}")
    right(c_ns_esc_char, "\\U0010FFFFz", "\u{10FFFF}")
  }

}
