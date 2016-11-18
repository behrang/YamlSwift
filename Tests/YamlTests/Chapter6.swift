import XCTest
import Parsec

@testable
import Yaml

class Chapter6: XCTestCase {

  func test_063_s_indent () {
    left(s_indent(2), "")
    left(s_indent(2), "z")
    left(s_indent(2), " z")
    left(s_indent(2), "\tz")
    left(s_indent(2), "\t z")
    left(s_indent(2), " \tz")
    right(s_indent(2), "  z")
    right(s_indent(2), "  \tz")
    right(s_indent(2), "   z")
  }

  func test_064_s_indent_less_than () {
    left(s_indent_less_than(2), "  ")
    left(s_indent_less_than(2), "  \t")
    left(s_indent_less_than(2), "   ")
    right(s_indent_less_than(2), "")
    right(s_indent_less_than(2), " ")
    right(s_indent_less_than(2), "\t")
    right(s_indent_less_than(2), "\t ")
    right(s_indent_less_than(2), " \t")
  }

  func test_065_s_indent_less_equal () {
    left(s_indent_less_equal(2), "   ")
    left(s_indent_less_equal(2), "   \t")
    left(s_indent_less_equal(2), "   ")
    right(s_indent_less_equal(2), "")
    right(s_indent_less_equal(2), " ")
    right(s_indent_less_equal(2), "\t")
    right(s_indent_less_equal(2), "\t ")
    right(s_indent_less_equal(2), " \t")
    right(s_indent_less_equal(2), "  ")
    right(s_indent_less_equal(2), "  \t")
  }

  func test_066_s_separate_in_line () {
    right(s_separate_in_line, "z")
    right(s_separate_in_line, "\nz")
    right(s_separate_in_line, " z")
    right(s_separate_in_line, " \tz")
    right(s_separate_in_line, "\tz")
    right(s_separate_in_line, "\t z")
  }

  func test_067_s_line_prefix () {
    left(s_line_prefix(2, .block_key), "  ")
    left(s_line_prefix(2, .block_in), "z")
    left(s_line_prefix(2, .block_in), " z")
    left(s_line_prefix(2, .flow_out), " z")
    left(s_line_prefix(2, .flow_out), " \tz")
    right(s_line_prefix(2, .block_in), "  ")
    right(s_line_prefix(2, .block_in), "  z")
    right(s_line_prefix(2, .block_in), "   z")
    right(s_line_prefix(2, .flow_out), "   z")
    right(s_line_prefix(2, .flow_out), "  z")
    right(s_line_prefix(2, .flow_out), "  \tz")
  }

  func test_070_l_empty () {
    left(l_empty(2, .block_key), "  \nz")
    left(l_empty(2, .block_out), "  z")
    right(l_empty(2, .block_out), "  \nz", "\n")
    right(l_empty(2, .block_out), " \nz", "\n")
    right(l_empty(2, .flow_in), "  \t\nz", "\n")
    right(l_empty(2, .flow_in), "  \t \t \nz", "\n")
    right(l_empty(2, .block_key), " \nz", "\n")
  }

  func test_071_b_l_trimmed () {
    left(b_l_trimmed(2, .block_key), "z")
    left(b_l_trimmed(2, .block_key), "  z")
    left(b_l_trimmed(2, .block_key), "  \n\nz")
    left(b_l_trimmed(2, .block_key), "\nz")
    left(b_l_trimmed(2, .block_key), "\n  \nz")
    right(b_l_trimmed(2, .block_key), "\n\nz", "\n")
    right(b_l_trimmed(2, .block_key), "\n \nz", "\n")
    right(b_l_trimmed(2, .block_key), "\n \n\nz", "\n\n")
    right(b_l_trimmed(2, .block_in), "\n \n \nz", "\n\n")
    right(b_l_trimmed(2, .block_in), "\n  \n  \nz", "\n\n")
  }

  func test_072_b_as_space () {
    left(b_as_space, "z")
    left(b_as_space, " z")
    right(b_as_space, "\nz", " ")
  }

  func test_073_b_l_folded () {
    left(b_l_folded(2, .block_key), "z")
    right(b_l_folded(2, .block_key), "\nz", " ")
    right(b_l_folded(2, .block_key), "\n\nz", "\n")
    right(b_l_folded(2, .block_key), "\n \nz", "\n")
    right(b_l_folded(2, .block_out), "\n  \nz", "\n")
    right(b_l_folded(2, .block_out), "\n  \n\n\nz", "\n\n\n")
    right(b_l_folded(2, .block_out), "\n  \n\n \nz", "\n\n\n")
    right(b_l_folded(2, .block_out), "\n  \n\n  \nz", "\n\n\n")
    right(b_l_folded(2, .block_out), "\n  \n  \n  \nz", "\n\n\n")
    right(b_l_folded(2, .block_out), "\n  \n  \n   \nz", "\n\n")
    right(b_l_folded(2, .block_out), "\n   \n  \n   \nz", " ")
    right(b_l_folded(2, .block_out), "\n  \n   \n   \nz", "\n")
    right(b_l_folded(2, .flow_out), "\n  \t \n   \n   \nz", "\n\n\n")
  }

  func test_074_s_flow_folded () {
    left(s_flow_folded(2), "z")
    left(s_flow_folded(2), " \t \n z")
    right(s_flow_folded(2), " \t \n  z", " ")
    right(s_flow_folded(2), " \t \n\n  z", "\n")
    right(s_flow_folded(2), "\n    \n  \tz", "\n")
    right(s_flow_folded(2), "\n    \n\n  \tz", "\n\n")
    right(s_flow_folded(2), "\n    \n \n  \tz", "\n\n")
  }

  func test_077_s_b_comment () {
    left(s_b_comment, "z")
    right(s_b_comment, "#z")
    right(s_b_comment, "# z")
    right(s_b_comment, " # z")
    right(s_b_comment, " # \nz")
    right(s_b_comment, " \t\nz")
    right(s_b_comment, " \t ")
  }

  func test_078_l_comment () {
    left(l_comment, "z")
    left(l_comment, "")
    right(l_comment, "\n")
    right(l_comment, "# z")
    right(l_comment, "# z\n")
    right(l_comment, " # z\n")
    right(l_comment, "\t# z\n")
    right(l_comment, " # z")
    right(l_comment, "\t# z")
    right(l_comment, " ")
    right(l_comment, "\t")
    right(l_comment, " \n")
    right(l_comment, "\t\n")
  }

  func test_079_s_l_comments () {
    right(s_l_comments, "\n #\n ")
  }

  func test_081_s_separate_lines () {
    right(s_separate_lines(2), "z")
    right(s_separate_lines(2), "\n z")
    right(s_separate_lines(2), " z")
    right(s_separate_lines(2), "\n  z")
  }

  func test_081_l_directive () {
    left(l_directive, "@")
    left(l_directive, "%")
    left(l_directive, "%YAML 1.2 3.4")
    left(l_directive, "%YAML ")
    left(l_directive, "%TAG ")
    left(l_directive, "%YAML 2.3")
    right(l_directive, "%YAM ", ("YAM", []))
    right(l_directive, "%YAM #", ("YAM", ["#"]))
    right(l_directive, "%YAM #z", ("YAM", ["#z"]))
    right(l_directive, "%YAMLZ #z", ("YAMLZ", ["#z"]))
    right(l_directive, "%YAML", ("YAML", []))
    right(l_directive, "%YAML 1.2", ("YAML", ["1.2"]))
    right(l_directive,
      "%TAG ! tag:example.com,2000:app/",
      ("TAG", ["!", "tag:example.com,2000:app/"]))
    right(l_directive,
      "%TAG !! tag:example.com,2000:app/",
      ("TAG", ["!!", "tag:example.com,2000:app/"]))
    right(l_directive,
      "%TAG !e! tag:example.com,2000:app/",
      ("TAG", ["!e!", "tag:example.com,2000:app/"]))
    right(l_directive,
      "%TAG !yaml! tag:yaml.org,2002:",
      ("TAG", ["!yaml!", "tag:yaml.org,2002:"]))
    right(l_directive,
      "%TAG !m! !my-",
      ("TAG", ["!m!", "!my-"]))
  }

  func test_096_c_ns_properties () {
    let tag_ex = Tag("tag:example.com,2000:app/x")
    let tag_et = Tag("tag:example.com,2000:app/tag!")
    let tag_foo = Tag("!foo")
    var tags = core_tags
    tags[tag_ex.uri] = tag_ex
    tags[tag_et.uri] = tag_et
    tags[tag_foo.uri] = tag_foo
    var schema = Schema(tags: tags, resolve: core_resolve)
    schema.handles["!e!"] = "tag:example.com,2000:app/"

    left(c_ns_properties(2, .block_key), "& ")
    right(c_ns_properties(2, .block_key), "!!!foo", (tag_non_specific, ""))
    right(c_ns_properties(2, .block_key), "!e!", (tag_non_specific, ""))
    right(c_ns_properties(2, .block_key), "! ", (tag_non_specific, ""))
    right(c_ns_properties(2, .block_key), "!e!x ", (tag_ex, ""), schema: schema)
    right(c_ns_properties(2, .block_key), "!foo", (tag_foo, ""), schema: schema)
    right(c_ns_properties(2, .block_key), "!<!foo>", (tag_foo, ""), schema: schema)
    right(c_ns_properties(2, .block_key), "!!str", (tag_string, ""))
    right(c_ns_properties(2, .block_key), "!e!tag%21", (tag_et, ""), schema: schema)
    right(c_ns_properties(2, .block_key), "!!str &a1", (tag_string, "a1"))
    right(c_ns_properties(2, .block_key), "&a1", (tag_unknown, "a1"))
    right(c_ns_properties(2, .block_key), "&1", (tag_unknown, "1"))
    right(c_ns_properties(2, .block_key), "&a1 !!str", (tag_string, "a1"))
    right(c_ns_properties(2, .block_key),
      "!<tag:yaml.org,2002:str>",
      (tag_string, ""))
  }

}
