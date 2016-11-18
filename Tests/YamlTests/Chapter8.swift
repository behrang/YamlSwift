import XCTest

@testable
import Yaml

class Chapter8: XCTestCase {

  func test_162_c_b_block_header () {
    left(c_b_block_header(0), "z")
    right(c_b_block_header(0), " # Empty header\n literal", (indent: 1, chomp: .clip))
    right(c_b_block_header(0), "1 # Indentation indicator\n  folded", (indent: 1, chomp: .clip))
    right(c_b_block_header(0), "+ # Chomping indicator\n keep", (indent: 1, chomp: .keep))
    right(c_b_block_header(0), "1- # Both indicators\n  strip", (indent: 1, chomp: .strip))
  }

  func test_163_c_indentation_indicator () {
    right(c_indentation_indicator(0), "\n detected", 1)
    right(c_indentation_indicator(0), "\n \n  \n  # detected", 2)
    right(c_indentation_indicator(0), "1\n  explicit", 1)
    right(c_indentation_indicator(0), "\n \t\n detected", 1)
  }

  func test_165_b_chomped_last () {
    right(b_chomped_last(.strip), "\n", "")
    right(b_chomped_last(.clip), "\n", "\n")
    right(b_chomped_last(.keep), "\n\n", "\n")
  }

  func test_166_l_chomped_empty () {
    right(l_chomped_empty(2, .strip), "  \n # Clip\n  # comments:\n\n", "")
    right(l_chomped_empty(2, .clip), " \n # Keep\n  # comments:\n\n", "")
    right(l_chomped_empty(2, .keep), "\n # Trail\n  # comments.", "\n")
  }

  func test_170_c_l_literal () {
    right(c_l_literal(0), "|\n literal\n \ttext\n\n", "literal\n\ttext\n")
    right(c_l_literal(0), "|\n \n  \n  literal\n   \n  \n  text\n\n # C", "\n\nliteral\n \n\ntext\n")
  }

  func test_174_c_l_folded () {
    right(c_l_folded(0), ">\n folded\n text\n\n", "folded text\n")
    right(c_l_folded(0),
      ">\n\n folded\n line\n\n next\n line\n   * bullet\n\n   * list\n   * lines\n\n last\n line\n\n# C",
      "\nfolded line\nnext line\n  * bullet\n\n  * list\n  * lines\n\nlast line\n")
  }

  func test_183_l_block_sequence () {
    let seq = Node.sequence([
      .scalar("one", tag_unknown),
      .mapping([
        .scalar("two", tag_unknown): .scalar("three", tag_unknown)
      ], tag_mapping)
    ], tag_sequence)
    let nested = Node.sequence([
      .scalar("entry", tag_unknown),
      .sequence([
        .scalar("nested", tag_unknown),
      ], tag_sequence)
    ], tag_sequence)
    right(l_block_sequence(0), "  - one\n  - two : three\n", seq)
    right(l_block_sequence(0),
      " - entry\n - !!seq\n  - nested\n",
      nested)
  }

  func test_184_c_l_block_seq_entry () {
    let twoThree = Node.mapping([
      .scalar("two", tag_unknown): .scalar("three", tag_unknown)
    ], tag_mapping)
    right(c_l_block_seq_entry(0), "- one\n", .scalar("one", tag_unknown))
    right(c_l_block_seq_entry(0), "- two : three\n", twoThree)
  }

  func test_185_s_l_block_indented () {
    let empty = Node.scalar("", tag_null)
    let block = Node.scalar("block node\n", tag_string)
    let seq = Node.sequence([
      .scalar("one", tag_unknown),
      .scalar("two", tag_unknown)
    ], tag_sequence)
    let map = Node.mapping([
      .scalar("one", tag_unknown): .scalar("two", tag_unknown)
    ], tag_mapping)
    right(s_l_block_indented(0, .block_out), " # Empty\n", empty)
    right(s_l_block_indented(0, .block_out), " |\n block node\n", block)
    right(s_l_block_indented(0, .block_out), " - one # Compact\n  - two # sequence\n", seq)
    right(s_l_block_indented(0, .block_out), " one: two # Compact mapping\n", map)
  }

  func test_186_ns_l_compact_sequence () {
    let seq = Node.sequence([
      .scalar("", tag_null),
      .scalar("block node\n", tag_string),
      .sequence([
        .scalar("one", tag_unknown),
        .scalar("two", tag_unknown)
      ], tag_sequence),
      .mapping([
        .scalar("one", tag_unknown): .scalar("two", tag_unknown)
      ], tag_mapping)
    ], tag_sequence)
    let block_nodes = Node.sequence([
      .scalar("flow in block", tag_string),
      .scalar("Block scalar\n", tag_string),
      .mapping([
        .scalar("foo", tag_unknown): .scalar("bar", tag_unknown)
      ], tag_mapping)
    ], tag_sequence)
    let sunEarthMoon = Node.sequence([
      .mapping([
        .scalar("sun", tag_unknown): .scalar("yellow", tag_unknown)
      ], tag_mapping),
      .mapping([
        .mapping([
          .scalar("earth", tag_unknown): .scalar("blue", tag_unknown)
        ], tag_mapping):
          .mapping([
            .scalar("moon", tag_unknown): .scalar("white", tag_unknown)
          ], tag_mapping)
      ], tag_mapping)
    ], tag_sequence)
    let array: [Node] = [
      .scalar("detected\n", tag_string),
      .scalar("\n\n# detected\n", tag_string),
      .scalar(" explicit\n", tag_string),
      .scalar("\t\ndetected", tag_string),
    ]
    let detected = Node.sequence(array, tag_sequence)
    let foo = Node.mapping([
      .scalar("foo", tag_unknown): Node.sequence(array, tag_non_specific)
    ], tag_mapping)
    right(ns_l_compact_sequence(0),
      "- # Empty\n- |\n block node\n- - one # Compact\n  - two # sequence\n- one: two # Compact mapping",
      seq)
    right(ns_l_compact_sequence(0),
      "-\n  \"flow in block\"\n- >\n Block scalar\n- !!map # Block collection\n  foo : bar\n",
      block_nodes)
    right(ns_l_compact_sequence(0),
      "- sun: yellow\n- ? earth: blue\n  : moon: white\n",
      sunEarthMoon)
    right(ns_l_compact_sequence(0),
      "- |\n detected\n- >\n \n  \n  # detected\n- |1\n  explicit\n- >\n \t\n detected",
      detected)
    right(ns_l_compact_mapping(0),
      "foo:\n - |\n  detected\n - >\n  \n   \n   # detected\n - |1\n   explicit\n - >\n  \t\n  detected",
      foo)
    right(ns_l_compact_mapping(0),
      "foo:\n- |\n detected\n- >\n \n  \n  # detected\n- |1\n  explicit\n- >\n \t\n detected",
      foo)
  }

  func test_195_ns_l_compact_mapping () {
    let sun = Node.mapping([
      .scalar("sun", tag_unknown): .scalar("yellow", tag_unknown)
    ], tag_mapping)
    let earth = Node.mapping([
      .scalar("earth", tag_unknown): .scalar("blue", tag_unknown)
    ], tag_mapping)
    let moon = Node.mapping([
      .scalar("moon", tag_unknown): .scalar("white", tag_unknown)
    ], tag_mapping)
    let complex = Node.mapping([earth: moon], tag_mapping)
    let explicit_key = Node.mapping([
      .scalar("explicit key", tag_unknown): .scalar("", tag_null)
    ], tag_mapping)
    let explicit = Node.mapping([
      .scalar("explicit key", tag_unknown): .scalar("", tag_null),
      .scalar("block key\n", tag_string): .sequence([
        .scalar("one", tag_unknown),
        .scalar("two", tag_unknown),
      ], tag_sequence),
    ], tag_mapping)
    let block_key = Node.mapping([
      .scalar("block key\n", tag_string): .sequence([
        .scalar("one", tag_unknown),
        .scalar("two", tag_unknown),
      ], tag_sequence)
    ], tag_mapping)
    let entry = Node.mapping([
      .scalar("quoted key", tag_unknown): .sequence([
        .scalar("entry", tag_unknown)
      ], tag_non_specific)
    ], tag_mapping)
    let entries = Node.mapping([
      .scalar("plain key", tag_unknown): .scalar("in-line value", tag_unknown),
      .scalar("", tag_null): .scalar("", tag_null),
      .scalar("quoted key", tag_unknown): .sequence([
        .scalar("entry", tag_unknown)
      ], tag_non_specific)
    ], tag_mapping)
    let block_scalar_nodes = Node.mapping([
      .scalar("literal", tag_unknown): .scalar("value\n", tag_string),
      .scalar("folded", tag_unknown): .scalar("value", tag_string),
    ], tag_mapping)
    let block_collection_nodes = Node.mapping([
      .scalar("sequence", tag_unknown): .sequence([
        .scalar("entry", tag_unknown),
        .sequence([
          .scalar("nested", tag_unknown)
        ], tag_sequence)
      ], tag_sequence),
      .scalar("mapping", tag_unknown): .mapping([
        .scalar("foo", tag_unknown): .scalar("bar", tag_unknown)
      ], tag_mapping)
    ], tag_mapping)
    let block_mapping = Node.mapping([
      .scalar("block mapping", tag_unknown): .mapping([
        .scalar("key", tag_unknown): .scalar("value", tag_unknown)
      ], tag_non_specific)
    ], tag_mapping)
    let block_sequence = Node.mapping([
      .scalar("block sequence", tag_unknown): .sequence([
        .scalar("one", tag_unknown),
        .mapping([
          .scalar("two", tag_unknown): .scalar("three", tag_unknown)
        ], tag_mapping)
      ], tag_non_specific)
    ], tag_mapping)
    right(ns_l_compact_mapping(0), "sun: yellow\n", sun)
    right(ns_l_compact_mapping(0), "? earth: blue\n: moon: white\n", complex)
    right(ns_l_compact_mapping(0), "? explicit key # Empty value\n", explicit_key)
    right(ns_l_compact_mapping(0),
      "? explicit key # Empty value\n? |\n  block key\n: - one # Explicit compact\n  - two # block\n",
      explicit)
    right(ns_l_compact_mapping(0),
      "? |\n  block key\n: - one # Explicit compact\n  - two # block value\n",
      block_key)
    right(ns_l_compact_mapping(0),
      "\"quoted key\":\n- entry",
      entry)
    right(ns_l_compact_mapping(0),
      "plain key: in-line value\n: # Both empty\n\"quoted key\":\n- entry",
      entries)
    right(ns_l_compact_mapping(0),
      "literal: |2\n  value\nfolded:\n   !!str\n  >1\n value",
      block_scalar_nodes)
    right(ns_l_compact_mapping(0),
      "sequence: !!seq\n- entry\n- !!seq\n - nested\nmapping: !!map\n foo: bar",
      block_collection_nodes)
    right(ns_l_compact_mapping(0),
      "block mapping:\n key: value\n",
      block_mapping)
    right(ns_l_compact_mapping(0),
      "block sequence:\n  - one\n  - two : three\n",
      block_sequence)
  }

  func test_200_s_l_block_collection () {
    let entries = Node.sequence([
      .scalar("entry", tag_unknown),
    ], tag_non_specific)
    let block_collection_nodes = Node.sequence([
      .scalar("entry", tag_unknown),
      .sequence([
        .scalar("nested", tag_unknown)
      ], tag_sequence)
    ], tag_sequence)
    right(s_l_block_collection(0, .block_out), "\n- entry", entries)
    right(s_l_block_collection(0, .block_out),
      " !!seq\n- entry\n- !!seq\n - nested\n",
      block_collection_nodes)
  }

}
