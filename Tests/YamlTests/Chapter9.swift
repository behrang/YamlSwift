import XCTest

@testable
import Yaml

class Chapter9: XCTestCase {

  func test_202_l_document_prefix () {
    right(l_document_prefix, "# Comment\n# lines\nDocument")
  }

  func test_205_l_document_suffix () {
    right(l_document_suffix, "... # Suffix")
  }

  func test_207_l_bare_document () {
    left(l_bare_document,
      "[\n...\n]")
    left(l_bare_document,
      "{\n...\n}")
    left(l_bare_document,
      "'\n...\n'")
    left(l_bare_document,
      "\"\n...\n\"")
    right(l_bare_document,
      "|\nx\n...",
      .scalar("x\n", tag_string, ""))
    right(l_bare_document,
      ">\nx\n--- ",
      .scalar("x\n", tag_string, ""))
    right(l_bare_document,
      "Bare\ndocument\n...\n",
      .scalar("Bare document", tag_non_specific, ""))
  }

  func test_211_l_yaml_stream () {
    right(l_yaml_stream,
      "# Comment\n# lines\nDocument",
      [ Node.scalar("Document", tag_non_specific, "") ])
    right(l_yaml_stream,
      "%YAML 1.2\n---\nDocument\n... # Suffix",
      [ Node.scalar("Document", tag_non_specific, "") ])
    right(l_yaml_stream,
      "Bare\ndocument\n...\n# No document\n...\n|\n%!PS-Adobe-2.0 # Not the first line",
      [ Node.scalar("Bare document", tag_non_specific, ""),
        Node.scalar("%!PS-Adobe-2.0 # Not the first line\n", tag_string, "")
      ])
    right(l_yaml_stream,
      "---\n{ matches\n% : 20 }\n...\n---\n# Empty\n...",
      [ Node.mapping([
          .scalar("matches %", tag_non_specific, ""): .scalar("20", tag_non_specific, "")
        ], tag_mapping, ""),
        Node.scalar("", tag_null, "")
      ])
    right(l_yaml_stream,
      "%YAML 1.2\n--- |\n%!PS-Adobe-2.0\n...\n%YAML1.2\n---\n# Empty\n...\n",
      [ Node.scalar("%!PS-Adobe-2.0\n", tag_string, ""),
        Node.scalar("", tag_null, "")
      ])
    right(l_yaml_stream,
      "Document\n---\n# Empty\n...\n%YAML 1.2\n---\nmatches %: 20",
      [ Node.scalar("Document", tag_non_specific, ""),
        Node.scalar("", tag_null, ""),
        Node.mapping([
          .scalar("matches %", tag_non_specific, ""): .scalar("20", tag_non_specific, "")
        ], tag_mapping, ""),
      ])
  }

}
