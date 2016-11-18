import XCTest
import Parsec

@testable
import Yaml

class Chapter7: XCTestCase {

  func test_104_c_ns_alias_node () {
    left(c_ns_alias_node, "*")
    left(c_ns_alias_node, "* ")
    left(c_ns_alias_node, "*a1 ")
    left(c_ns_alias_node, "*1 ")
  }

  func test_106_e_node () {
    let e: Node = .scalar("", tag_null)
    right(e_node, "", e)
    right(e_node, "z", e)
  }

  func test_107_nb_double_char () {
    left(nb_double_char, "\\")
    left(nb_double_char, "\\1")
    left(nb_double_char, "\"")
    right(nb_double_char, " ", " ")
    right(nb_double_char, "\t", "\t")
    right(nb_double_char, "\\n", "\n")
  }

  func test_108_ns_double_char () {
    left(ns_double_char, "\\")
    left(ns_double_char, "\\1")
    left(ns_double_char, "\"")
    left(ns_double_char, " ")
    left(ns_double_char, "\t")
    right(ns_double_char, "\\n", "\n")
  }

  func test_109_c_double_quoted () {
    left(c_double_quoted(2, .block_key), "\"\n  \"")
    right(c_double_quoted(2, .flow_out), "\"\n  \"", .scalar(" ", tag_string))
    right(c_double_quoted(2, .block_key), "\"\"", .scalar("", tag_string))
    right(c_double_quoted(2, .block_key), "\" \"", .scalar(" ", tag_string))
  }

  func test_112_s_double_escaped () {
    left(s_double_escaped(2), " \t \\\n")
    left(s_double_escaped(2), " \t \\\n ")
    right(s_double_escaped(2), " \t \\\n  ", " \t ")
    right(s_double_escaped(2), " \t \\\n\n  ", " \t \n")
    right(s_double_escaped(2), " \t \\\n \n  ", " \t \n")
    right(s_double_escaped(2), " \t \\\n   \n  ", " \t \n")
    right(s_double_escaped(2), " \t \\\n   \n\n  ", " \t \n\n")
  }

  func test_113_s_double_break () {
    right(s_double_break(2), " \t \\\n   \n\n  ", " \t \n\n")
    right(s_double_break(2), " \t \n   \n\n  ", "\n\n")
    right(s_double_break(2), "\n  \t \\", " ")
  }

  func test_114_nb_ns_double_in_line () {
    right(nb_ns_double_in_line, " \ta bc \t  def", " \ta bc \t  def")
    right(nb_ns_double_in_line, " \ta bc \t  def \n", " \ta bc \t  def")
  }

  func test_115_s_double_next_line () {
    right(s_double_next_line(0), "\n\n x yz \n\tab c", "\nx yz ab c")
    right(s_double_next_line(0), "\n\n x yz \n\tab c ", "\nx yz ab c ")
    right(s_double_next_line(0), "\n\n x yz \n\tab c \n", "\nx yz ab c ")
  }

  func test_116_nb_double_multi_line () {
    right(nb_double_multi_line(0),
      "a bc x \ny\t\n \nz \t",
      "a bc x y\nz \t")
    right(nb_double_multi_line(0),
      " 1st non-empty\n\n 2nd non-empty \n\t3rd non-empty ",
      " 1st non-empty\n2nd non-empty 3rd non-empty ")
  }

  func test_118_nb_single_char () {
    left(nb_single_char, "'")
    left(nb_single_char, "'x")
    right(nb_single_char, " ", " ")
    right(nb_single_char, "\t", "\t")
    right(nb_single_char, "\\", "\\")
    right(nb_single_char, "''", "'")
  }

  func test_119_ns_single_char () {
    left(ns_single_char, "'")
    left(ns_single_char, "'x")
    left(ns_single_char, " ")
    left(ns_single_char, "\t")
    right(ns_single_char, "\\", "\\")
    right(ns_single_char, "''", "'")
  }

  func test_120_c_single_quoted () {
    left(c_single_quoted(2, .block_key), "'\n  '")
    right(c_single_quoted(2, .flow_out), "'\n  '", .scalar(" ", tag_string))
    right(c_single_quoted(2, .block_key), "''", .scalar("", tag_string))
    right(c_single_quoted(2, .block_key), "' '", .scalar(" ", tag_string))
  }

  func test_123_nb_ns_single_in_line () {
    right(nb_ns_single_in_line, " \ta bc \t  def", " \ta bc \t  def")
    right(nb_ns_single_in_line, " \ta bc \t  def \n", " \ta bc \t  def")
  }

  func test_124_s_single_next_line () {
    right(s_single_next_line(0), "\n\n x yz \n\tab c", "\nx yz ab c")
    right(s_single_next_line(0), "\n\n x yz \n\tab c ", "\nx yz ab c ")
    right(s_single_next_line(0), "\n\n x yz \n\tab c \n", "\nx yz ab c ")
  }

  func test_125_nb_single_multi_line () {
    right(nb_single_multi_line(0),
      "a bc x \ny\t\n \nz \t",
      "a bc x y\nz \t")
    right(nb_single_multi_line(0),
      " 1st non-empty\n\n 2nd non-empty \n\t3rd non-empty ",
      " 1st non-empty\n2nd non-empty 3rd non-empty ")
  }

  func test_126_ns_plain_first () {
    left(ns_plain_first(.block_key), "?")
    left(ns_plain_first(.block_out), "?a")
    right(ns_plain_first(.flow_out), "?#", "?")
    right(ns_plain_first(.block_key), "a", "a")
    right(ns_plain_first(.block_key), "?a", "?")
    right(ns_plain_first(.flow_in), "?a", "?")
    right(ns_plain_first(.flow_in), "?#", "?")
  }

  func test_130_ns_plain_char () {
    left(ns_plain_char(.block_key), ":")
    left(ns_plain_char(.flow_key), ":[")
    right(ns_plain_char(.block_key), "a", "a")
    right(ns_plain_char(.block_key), "-", "-")
    right(ns_plain_char(.block_key), ":ab", ":")
    right(ns_plain_char(.block_key), ":#a", ":")
    right(ns_plain_char(.block_key), ":[", ":")
  }

  func test_132_nb_ns_plain_in_line () {
    right(nb_ns_plain_in_line(.block_key), " \ta", " \ta")
    right(nb_ns_plain_in_line(.block_key), " \ta \n", " \ta")
  }

  func test_133_ns_plain_one_line () {
    right(ns_plain_one_line(.block_key), "a", "a")
    right(ns_plain_one_line(.block_key), "ab", "ab")
    right(ns_plain_one_line(.block_key), "a b\n c", "a b")
  }

  func test_134_s_ns_plain_next_line () {
    left(s_ns_plain_next_line(2, .block_key), "\n\n x")
    right(s_ns_plain_next_line(2, .block_key), "\n\n  x", "\nx")
    right(s_ns_plain_next_line(2, .block_key), "\n   \n  x", "\nx")
    right(s_ns_plain_next_line(2, .block_key), "\n   \n  x y ", "\nx y")
  }

  func test_135_ns_plain_multi_line () {
    right(ns_plain_multi_line(0, .block_key),
      "a bc x \ny\t\n \nz \t",
      "a bc x y\nz")
    right(ns_plain_multi_line(0, .block_key),
      "1st non-empty\n\n 2nd non-empty \n\t3rd non-empty",
      "1st non-empty\n2nd non-empty 3rd non-empty")
  }

  func test_137_c_flow_sequence () {
    let xy: Node = .sequence([
      .scalar("x", tag_string),
      .scalar("y", tag_string)
    ], tag_sequence)
    let xy_non_specific: Node = .sequence([
      .scalar("x", tag_unknown),
      .scalar("y", tag_unknown)
    ], tag_sequence)
    right(c_flow_sequence(0, .flow_out), "[x, y]", xy_non_specific)
    right(c_flow_sequence(0, .flow_out), "['x', \"y\"]", xy)
  }

  func test_138_ns_s_flow_seq_entries () {
    let n1: [Node] = [.scalar("x", tag_string)]
    let n2: [Node] = [.scalar("x", tag_string), .scalar("y", tag_string)]
    right(ns_s_flow_seq_entries(2, .flow_out), "'x'", n1)
    right(ns_s_flow_seq_entries(2, .flow_out), "'x' ", n1)
    right(ns_s_flow_seq_entries(2, .flow_out), "'x' ,", n1)
    right(ns_s_flow_seq_entries(2, .flow_out), "'x' , ", n1)
    right(ns_s_flow_seq_entries(2, .flow_out), "'x' , 'y'", n2)
  }

}
