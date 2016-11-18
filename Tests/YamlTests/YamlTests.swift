import XCTest

@testable
import Yaml

class YamlTests: XCTestCase {

  func testNull() {
    XCTAssert(try Yaml.load("# comment line") == [])
    XCTAssert(try Yaml.load("") == [])
    XCTAssert(try Yaml.load("null") == [.null])
    XCTAssert(try Yaml.load("Null") == [nil])
    XCTAssert(try Yaml.load("NULL") == [.null])
    XCTAssert(try Yaml.load("~") == [nil])
    XCTAssert(try Yaml.load("NuLL") == ["NuLL"])
    XCTAssert(try Yaml.load("null#") == ["null#"])
    XCTAssert(try Yaml.load("null#string") == ["null#string"])
    XCTAssert(try Yaml.load("null #comment") == [nil])

    let value: Yaml = nil
    XCTAssert(value == nil)
  }

  func testBool() {
    XCTAssert(try Yaml.load("true") == [.bool(true)])
    XCTAssert(try Yaml.load("True")[0].bool == true)
    XCTAssert(try Yaml.load("TRUE") == [true])
    XCTAssert(try Yaml.load("trUE") == ["trUE"])
    XCTAssert(try Yaml.load("true#") == ["true#"])
    XCTAssert(try Yaml.load("true#string") == ["true#string"])
    XCTAssert(try Yaml.load("true #comment") == [true])
    XCTAssert(try Yaml.load("true  #") == [true])
    XCTAssert(try Yaml.load("true  ") == [true])
    XCTAssert(try Yaml.load("true\n") == [true])
    XCTAssert(try Yaml.load("true \n") == [true])
    XCTAssert([true] == (try Yaml.load("\ntrue \n")))

    XCTAssert(try Yaml.load("false") == [.bool(false)])
    XCTAssert(try Yaml.load("False")[0].bool == false)
    XCTAssert(try Yaml.load("FALSE") == [false])
    XCTAssert(try Yaml.load("faLSE") == ["faLSE"])
    XCTAssert(try Yaml.load("false#") == ["false#"])
    XCTAssert(try Yaml.load("false#string") == ["false#string"])
    XCTAssert(try Yaml.load("false #comment") == [false])
    XCTAssert(try Yaml.load("false  #") == [false])
    XCTAssert(try Yaml.load("false  ") == [false])
    XCTAssert(try Yaml.load("false\n") == [false])
    XCTAssert(try Yaml.load("false \n") == [false])
    XCTAssert([false] == (try Yaml.load("\nfalse \n")))

    let value: Yaml = true
    XCTAssert(value == true)
    XCTAssert(value.bool == true)
  }

  func testInt() {
    XCTAssert(try Yaml.load("0") == [.int(0)])
    XCTAssert(try Yaml.load("+0")[0].int == 0)
    XCTAssert(try Yaml.load("-0") == [0])
    XCTAssert(try Yaml.load("2") == [2])
    XCTAssert(try Yaml.load("+2") == [2])
    XCTAssert(try Yaml.load("-2") == [-2])
    XCTAssert(try Yaml.load("00123") == [123])
    XCTAssert(try Yaml.load("+00123") == [123])
    XCTAssert(try Yaml.load("-00123") == [-123])
    XCTAssert(try Yaml.load("0o10") == [8])
    XCTAssert(try Yaml.load("0o010") == [8])
    XCTAssert(try Yaml.load("0o0010") == [8])
    XCTAssert(try Yaml.load("0x10") == [16])
    XCTAssert(try Yaml.load("0x1a") == [26])
    XCTAssert(try Yaml.load("0x01a") == [26])
    XCTAssert(try Yaml.load("0x001a") == [26])

    XCTAssert(try Yaml.load("2") == [2])
    XCTAssert(try Yaml.load("2.0") == [2])
    XCTAssert(try Yaml.load("2.5") != [2])
    XCTAssert(try Yaml.load("2.5")[0].int == nil)

    let value1: Yaml = 2
    XCTAssert(value1 == 2)
    XCTAssert(value1.int == 2)
    let value2: Yaml = -2
    XCTAssert(value2 == -2)
    XCTAssert(-value2 == 2)
    XCTAssert(-value2 == value1)
  }

  func testDouble() {
    XCTAssert(try Yaml.load(".inf") == [.double(Double.infinity)])
    XCTAssert(try Yaml.load(".Inf")[0].double == Double.infinity)
    XCTAssert(try Yaml.load(".INF")[0].double == Double.infinity)
    XCTAssert(try Yaml.load(".iNf") == [".iNf"])
    XCTAssert(try Yaml.load(".inf#") == [".inf#"])
    XCTAssert(try Yaml.load(".inf# string") == [".inf# string"])
    XCTAssert(try Yaml.load(".inf # comment")[0].double == Double.infinity)
    XCTAssert(try Yaml.load(".inf .inf") == [".inf .inf"])
    XCTAssert(try Yaml.load("+.inf # comment")[0].double == Double.infinity)

    XCTAssert(try Yaml.load("-.inf") == [.double(-Double.infinity)])
    XCTAssert(try Yaml.load("-.Inf")[0].double == -Double.infinity)
    XCTAssert(try Yaml.load("-.INF")[0].double == -Double.infinity)
    XCTAssert(try Yaml.load("-.iNf") == ["-.iNf"])
    XCTAssert(try Yaml.load("-.inf#") == ["-.inf#"])
    XCTAssert(try Yaml.load("-.inf# string") == ["-.inf# string"])
    XCTAssert(try Yaml.load("-.inf # comment")[0].double == -Double.infinity)
    XCTAssert(try Yaml.load("-.inf -.inf") == ["-.inf -.inf"])

    XCTAssert(try Yaml.load(".nan") != [.double(Double.nan)])
    XCTAssert(try Yaml.load(".nan")[0].double!.isNaN)
    XCTAssert(try Yaml.load(".NaN")[0].double!.isNaN)
    XCTAssert(try Yaml.load(".NAN")[0].double!.isNaN)
    XCTAssert(try Yaml.load(".Nan")[0].double == nil)
    XCTAssert(try Yaml.load(".nan#") == [".nan#"])
    XCTAssert(try Yaml.load(".nan# string") == [".nan# string"])
    XCTAssert(try Yaml.load(".nan # comment")[0].double!.isNaN)
    XCTAssert(try Yaml.load(".nan .nan") == [".nan .nan"])

    XCTAssert(try Yaml.load("0.") == [.double(0)])
    XCTAssert(try Yaml.load(".0")[0].double == 0)
    XCTAssert(try Yaml.load("+0.") == [0])
    XCTAssert(try Yaml.load("+.0") == [0])
    XCTAssert(try Yaml.load("+.") != [0])
    XCTAssert(try Yaml.load("-0.") == [0])
    XCTAssert(try Yaml.load("-.0") == [0])
    XCTAssert(try Yaml.load("-.") != [0])
    XCTAssert(try Yaml.load("2.") == [2])
    XCTAssert(try Yaml.load(".2") == [0.2])
    XCTAssert(try Yaml.load("+2.") == [2])
    XCTAssert(try Yaml.load("+.2") == [0.2])
    XCTAssert(try Yaml.load("-2.") == [-2])
    XCTAssert(try Yaml.load("-.2") == [-0.2])
    XCTAssert(try Yaml.load("1.23015e+3") == [1.23015e+3])
    XCTAssert(try Yaml.load("12.3015e+02") == [12.3015e+02])
    XCTAssert(try Yaml.load("1230.15") == [1230.15])
    XCTAssert(try Yaml.load("+1.23015e+3") == [1.23015e+3])
    XCTAssert(try Yaml.load("+12.3015e+02") == [12.3015e+02])
    XCTAssert(try Yaml.load("+1230.15") == [1230.15])
    XCTAssert(try Yaml.load("-1.23015e+3") == [-1.23015e+3])
    XCTAssert(try Yaml.load("-12.3015e+02") == [-12.3015e+02])
    XCTAssert(try Yaml.load("-1230.15") == [-1230.15])
    XCTAssert(try Yaml.load("-01230.15") == [-1230.15])
    XCTAssert(try Yaml.load("-12.3015e02") == [-12.3015e+02])

    XCTAssert(try Yaml.load("2") == [2.0])
    XCTAssert(try Yaml.load("2.0") == [2.0])
    XCTAssert(try Yaml.load("2.5") == [2.5])
    XCTAssert(try Yaml.load("2.5")[0].int == nil)

    let value1: Yaml = 0.2
    XCTAssert(value1 == 0.2)
    XCTAssert(value1.double == 0.2)
    let value2: Yaml = -0.2
    XCTAssert(value2 == -0.2)
    XCTAssert(-value2 == 0.2)
    XCTAssert(-value2 == value1)
  }

  func testString () {
    XCTAssert(try Yaml.load("Behrang") == [.string("Behrang")])
    XCTAssert(try Yaml.load("\"Behrang\"") == [.string("Behrang")])
    XCTAssert(try Yaml.load("\"B\\\"ehran\\\"g\"") == [.string("B\"ehran\"g")])
    XCTAssert(try Yaml.load("Behrang Noruzi Niya")[0].string ==
      "Behrang Noruzi Niya")
    XCTAssert(try Yaml.load("Radin Noruzi Niya") == ["Radin Noruzi Niya"])
    XCTAssert(try Yaml.load("|") == [""])
    XCTAssert(try Yaml.load("| ") == [""])
    XCTAssert(try Yaml.load("|  # comment") == [""])
    XCTAssert(try Yaml.load("|  # comment\n") == [""])

    XCTAssert(try Yaml.load("|\nRadin") == ["Radin"])
    XCTAssert(try Yaml.load("|\nRadin\n") == ["Radin\n"])
    XCTAssert(try Yaml.load("|\n Radin") == ["Radin"])
    XCTAssert(try Yaml.load("|  \n Radin") == ["Radin"])
    XCTAssert(try Yaml.load("|  # comment\n Radin") == ["Radin"])
    XCTAssert(try Yaml.load("|\n  Radin") == ["Radin"])
    XCTAssert(try Yaml.load("|2\n  Radin") == [" Radin"])
    XCTAssert(try Yaml.load("|1\n  Radin") == ["  Radin"])
    XCTAssert(try Yaml.load("|1\n\n  Radin") == ["\n  Radin"])
    XCTAssert(try Yaml.load("|\n\n  Radin") == ["\nRadin"])
    XCTAssert(try Yaml.load("|3\n\n  Radin") == ["\nRadin"])
    XCTAssert(try Yaml.load("|3\n    \n   Radin") == ["  \n Radin"])
    XCTAssert(try Yaml.load("|3\n   \n   Radin") == [" \n Radin"])
    XCTAssert(try Yaml.load("|\n  \n\n \n  Radin\n\n \n\n  Noruzi Niya") ==
      ["\n\n\nRadin\n\n\n\nNoruzi Niya"])
    XCTAssert(try Yaml.load("|\n  \n\n \n  Radin\n\n \n\n  Noruzi Niya\n  #1") ==
      ["\n\n\nRadin\n\n\n\nNoruzi Niya\n#1"])
    XCTAssert(try Yaml.load("|\n  \n\n \n  Radin\n\n \n\n  Noruzi Niya\n  #1" +
      "\n # Comment") == ["\n\n\nRadin\n\n\n\nNoruzi Niya\n#1\n"])
    XCTAssert(try Yaml.load("|\n Radin\n") == ["Radin\n"])
    XCTAssert(try Yaml.load("|\n Radin\n\n") == ["Radin\n"])
    XCTAssert(try Yaml.load("|\n Radin\n \n ") == ["Radin\n"])
    XCTAssert(try Yaml.load("|\n Radin\n  \n  ") == ["Radin\n \n "])
    XCTAssert(try Yaml.load("|-\n Radin\n  \n  ") == ["Radin\n \n "])
    XCTAssert(try Yaml.load("|+\n Radin\n") == ["Radin\n"])
    XCTAssert(try Yaml.load("|+\n Radin\n\n") == ["Radin\n\n"])
    XCTAssert(try Yaml.load("|+\n Radin\n \n ") == ["Radin\n\n"])
    XCTAssert(try Yaml.load("|+\n Radin\n  \n  ") == ["Radin\n \n "])
    XCTAssert(try Yaml.load("|2+\n  Radin\n  \n  ") == [" Radin\n \n "])
    XCTAssert(try Yaml.load("|+2\n  Radin\n  \n  ") == [" Radin\n \n "])
    XCTAssert(try Yaml.load("|-2\n  Radin\n  \n  ") == [" Radin\n \n "])
    XCTAssert(try Yaml.load("|2-\n  Radin\n  \n  ") == [" Radin\n \n "])
    XCTAssertThrowsError(try Yaml.load("|22\n  Radin\n  \n  "))
    XCTAssertThrowsError(try Yaml.load("|--\n  Radin\n  \n  "))
    XCTAssert(try Yaml.load(">+\n  trimmed\n  \n \n\n  as\n  space\n\n   \n") ==
      ["trimmed\n\n\nas space\n\n \n"])
    XCTAssert(try Yaml.load(">-\n  trimmed\n  \n \n\n  as\n  space") ==
      ["trimmed\n\n\nas space"])
    XCTAssert(try Yaml.load(">\n  foo \n \n  \t bar\n\n  baz\n") ==
      ["foo \n\n\t bar\n\nbaz\n"])

    XCTAssertThrowsError(try Yaml.load(">\n  \n Behrang"))
    XCTAssert(try Yaml.load(">\n  \n  Behrang") == ["\nBehrang"])
    XCTAssert(try Yaml.load(">\n\n folded\n line\n\n next\n line\n   * bullet\n\n" +
      "   * list\n   * lines\n\n last\n line\n\n# Comment")[0] ==
      .string("\nfolded line\nnext line\n  * bullet\n\n  * list\n  * lines" +
        "\n\nlast line\n"))

    XCTAssert(try Yaml.load("\"\n  foo \n \n  \t bar\n\n  baz\n\"") ==
      [" foo\nbar\nbaz "])
    XCTAssert(try Yaml.load("\"folded \nto a space,\t\n \nto a line feed," +
      " or \t\\\n \\ \tnon-content\"") ==
      ["folded to a space,\nto a line feed, or \t \tnon-content"])
    XCTAssert(try Yaml.load("\" 1st non-empty\n\n 2nd non-empty" +
      " \n\t3rd non-empty \"") ==
      [" 1st non-empty\n2nd non-empty 3rd non-empty "])

    XCTAssert(try Yaml.load("'here''s to \"quotes\"'") == ["here's to \"quotes\""])
    XCTAssert(try Yaml.load("' 1st non-empty\n\n 2nd non-empty" +
      " \n\t3rd non-empty '") ==
      [" 1st non-empty\n2nd non-empty 3rd non-empty "])

    XCTAssert(try Yaml.load("x\n y\nz") == ["x y z"])
    XCTAssert(try Yaml.load(" x\ny\n z") == ["x y z"])
    XCTAssert(try Yaml.load("a: x\n y\n  z") == [["a": "x y z"]])
    XCTAssertThrowsError(try Yaml.load("a: x\ny\n  z"))
    XCTAssert(try Yaml.load("- a: x\n   y\n    z") == [[["a": "x y z"]]])
    XCTAssert(try Yaml.load("- a:\n   x\n    y\n   z") == [[["a": "x y z"]]])
    XCTAssert(try Yaml.load("- a:     \n   x\n    y\n   z") == [[["a": "x y z"]]])
    XCTAssert(try Yaml.load("- a: # comment\n   x\n    y\n   z") ==
      [[["a": "x y z"]]])

    let value1: Yaml = "Radin"
    XCTAssert(value1 == "Radin")
    XCTAssert(value1.string == "Radin")

    let value2 = try! Yaml.load(
      "# Outside flow collection:\n" +
        "- ::vector\n" +
        "- \": - ()\"\n" +
        "- Up, up, and away!\n" +
        "- -123\n" +
        "- http://example.com/foo#bar\n" +
        "# Inside flow collection:\n" +
        "- [ ::vector,\n" +
        "  \": - ()\",\n" +
        "  \"Up, up, and away!\",\n" +
        "  -123,\n" +
      "  http://example.com/foo#bar ]\n"
      )[0]
    let value3: Yaml = [
      "::vector",
      ": - ()",
      "Up, up, and away!",
      -123,
      "http://example.com/foo#bar",
      [ "::vector",
        ": - ()",
        "Up, up, and away!",
        -123,
        "http://example.com/foo#bar"
      ]
    ]
    XCTAssert(value2 == value3)
    XCTAssert(value2.count == 6)
    XCTAssert(value2[0] == "::vector")
    XCTAssert(value2[5][0] == "::vector")
    XCTAssert(value2[5][4] == "http://example.com/foo#bar")
  }

  func testFlowSeq () {
    XCTAssert(try Yaml.load("[]")[0] == .array([]))
    XCTAssert(try Yaml.load("[]")[0].count == 0)
    XCTAssert(try Yaml.load("[ true ]") == [[Yaml.bool(true)]])
    XCTAssert(try Yaml.load("[ true ]")[0] == .array([true]))
    XCTAssert(try Yaml.load("[ true ]") == [[true]])
    XCTAssert(try Yaml.load("[ true ]")[0][0] == true)
    XCTAssert(try Yaml.load("[true, false, true]") == [[true, false, true]])
    XCTAssert(try Yaml.load("[Behrang, Radin]") == [["Behrang", "Radin"]])
    XCTAssert(try Yaml.load("[true, [false, true]]") == [[true, [false, true]]])
    XCTAssert(try Yaml.load("[true, true  ,false,  false  ,  false]") ==
      [[true, true, false, false, false]])
    XCTAssert(try Yaml.load("[true, .NaN]") != [[true, .double(Double.nan)]])
    XCTAssert(try Yaml.load("[~, null, TRUE, False, .INF, -.inf, 0, 123, -456" +
      ", 0o74, 0xFf, 1.23, -4.5]") ==
      [[nil, nil, true, false,
        .double(Double.infinity), .double(-Double.infinity),
        0, 123, -456, 60, 255, 1.23, -4.5]])
    XCTAssertThrowsError(try Yaml.load("x:\n y:\n  z: [\n1]"))
    XCTAssertThrowsError(try Yaml.load("x:\n y:\n  z: [\n  1]"))
    XCTAssert(try Yaml.load("x:\n y:\n  z: [\n   1]") == [["x": ["y": ["z": [1]]]]])
  }

  func testBlockSeq () {
    XCTAssert(try Yaml.load("- 1\n- 2") == [[1, 2]])
    XCTAssert(try Yaml.load("- 1\n- 2")[0][1] == 2)
    XCTAssert(try Yaml.load("- x: 1") == [[["x": 1]]])
    XCTAssert(try Yaml.load("- x: 1\n  y: 2")[0][0] == ["x": 1, "y": 2])
    XCTAssert(try Yaml.load("- 1\n    \n- x: 1\n  y: 2") == [[1, ["x": 1, "y": 2]]])
    XCTAssert(try Yaml.load("- x:\n  - y: 1") == [[["x": [["y": 1]]]]])

    let space1020 = repeatElement(" ", count: 1020).joined(separator: "")
    let implicit1 = "- [ YAML\(space1020): separate ]"
    let implicit2 = "- [  YAML\(space1020): separate ]"
    let implicit3 = "- [ YAML\(space1020) : separate ]"
    XCTAssert(try Yaml.load(implicit1) == [[[["YAML": "separate"]]]])
    XCTAssert(try Yaml.load(implicit2) == [[[["YAML": "separate"]]]])
    XCTAssertThrowsError(try Yaml.load(implicit3))
  }

  func testFlowMap () {
    XCTAssert(try Yaml.load("{}") == [[:]])
    XCTAssert(try Yaml.load("{x: 1}") == [["x": 1]])
    XCTAssertThrowsError(try Yaml.load("{x: 1, x: 2}"))
    XCTAssert(try Yaml.load("{x: 1}")[0]["x"] == 1)
    XCTAssert(try Yaml.load("{x:1}") == [["x:1": nil]])
    XCTAssert(try Yaml.load("{\"x\":1}")[0]["x"] == 1)
    XCTAssert(try Yaml.load("{\"x\":1, 'y': true}")[0]["y"] == true)
    XCTAssert(try Yaml.load("{\"x\":1, 'y': true, z: null}")[0]["z"] == nil)
    XCTAssert(try Yaml.load("{first name: \"Behrang\"," +
      " last name: 'Noruzi Niya'}") ==
      [["first name": "Behrang", "last name": "Noruzi Niya"]])
    XCTAssert(try Yaml.load("{fn: Behrang, ln: Noruzi Niya}")[0]["ln"] ==
      "Noruzi Niya")
    XCTAssert(try Yaml.load("{fn: Behrang\n ,\nln: Noruzi Niya}")[0]["ln"] ==
      "Noruzi Niya")
  }

  func testBlockMap () {
    XCTAssert(try Yaml.load("x: 1\ny: 2")[0] ==
      .dictionary([.string("x"): .int(1), .string("y"): .int(2)]))
    XCTAssertThrowsError(try Yaml.load("x: 1\nx: 2"))
    XCTAssert(try Yaml.load("x: 1\n? y\n: 2") == [["x": 1, "y": 2]])
    XCTAssertThrowsError(try Yaml.load("x: 1\n? x\n: 2"))
    XCTAssertThrowsError(try Yaml.load("x: 1\n?  y\n:\n2"))
    XCTAssert(try Yaml.load("x: 1\n?  y\n:\n 2") == [["x": 1, "y": 2]])
    XCTAssert(try Yaml.load("x: 1\n?  y") == [["x": 1, "y": nil]])
    XCTAssert(try Yaml.load("?  y") == [["y": nil]])
    XCTAssert(try Yaml.load(" \n  \n \n  \n\nx: 1  \n   \ny: 2" +
      "\n   \n  \n ")[0]["y"] == 2)
    XCTAssert(try Yaml.load("x:\n a: 1 # comment \n b: 2\ny: " +
      "\n  c: 3\n  ")[0]["y"]["c"] == 3)
    XCTAssert(try Yaml.load("# comment \n\n  # x\n  # y \n  \n  x: 1" +
      "  \n  y: 2") == [["x": 1, "y": 2]])
  }

  func testDirectives () {
    XCTAssertThrowsError(try Yaml.load("%YAML 1.2\n1"))
    XCTAssertThrowsError(try Yaml.load("%YAML   1.2\n---1"))
    XCTAssert(try Yaml.load("%YAML   1.2\n---\n1") == [1])
    XCTAssert(try Yaml.load("%YAML   1.2  #\n---\n1") == [1])
    XCTAssertThrowsError(try Yaml.load("%YAML   1.2\n%YAML 1.2\n---\n1"))
    XCTAssertThrowsError(try Yaml.load("%YAML 1.0\n---\n1"))
    XCTAssertThrowsError(try Yaml.load("%YAML 1\n---\n1"))
    XCTAssert(try Yaml.load("%YAML 1.1\n---\n1") == [1])
    XCTAssert(try Yaml.load("%YAML 1.3\n---\n1") == [1])
    XCTAssertThrowsError(try Yaml.load("%YAML \n---\n1"))
    XCTAssert(try Yaml.load("%TAG ! !\n---\n! 1") == ["1"])
    XCTAssert(try Yaml.load("%TAG ! tag:yaml.org,2002:\n---\n!str 1") == ["1"])
    XCTAssertThrowsError(try Yaml.load("%TAG ! tag:yaml.org,2001:\n---\n!str 1"))
    XCTAssert(try Yaml.load("%TAG !! tag:yaml.org,2002:\n---\n!!int 1") == [1])
    XCTAssertThrowsError(try Yaml.load("%TAG !! tag:yaml.org,2001:\n---\n!!int 1"))
    XCTAssert(try Yaml.load("%TAG !yaml! tag:yaml.org,2002:\n---\n!yaml!int 1") == [1])
    XCTAssertThrowsError(try Yaml.load("%TAG !yaml! tag:yaml.org,2002:\n" +
      "%TAG !yaml! tag:yaml.org,2002:\n---\n1"))
  }

  func testReserves () {
    XCTAssertThrowsError(try Yaml.load("`reserved"))
    XCTAssertThrowsError(try Yaml.load("@behrangn"))
    XCTAssertThrowsError(try Yaml.load("twitter handle: @behrangn"))
  }

  func testAliases () {
    XCTAssert(try Yaml.load("x: &a 1\ny: *a") == [["x": 1, "y": 1]])
    XCTAssert(try Yaml.load("x: &a 1\ny: *a\n---\nx: *a") == [["x": 1, "y": 1], ["x": 1]])
    XCTAssertThrowsError(try Yaml.load("x: *a"))

    let value1 = try! Yaml.load("maps:\n  seq1: &alias1\n  - scalar1\n  - scalar2\n  seq2: *alias1")[0]
    XCTAssert(value1 == ["maps": ["seq1": ["scalar1", "scalar2"], "seq2": ["scalar1", "scalar2"]]])
    XCTAssert(value1["maps"]["seq1"] == value1["maps"]["seq2"])

    // todo: support circular references
    // let _ = try! Yaml.load("x: &a\n  y: 1\n  z: 2\n  w: *a")[0]

  }

  func testUnicodeSurrogates() {
    XCTAssert(try Yaml.load("x: Dog‼🐶\ny: 𝒂𝑡") == [["x": "Dog‼🐶", "y": "𝒂𝑡"]])
  }

}
