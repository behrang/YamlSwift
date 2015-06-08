import Yaml
import XCTest

class YamlTests: XCTestCase {
  
  func testNull() {
    XCTAssert(Yaml.load("# comment line").value! == .Null)
    XCTAssert(Yaml.load("").value! == .Null)
    XCTAssert(Yaml.load("null").value! == .Null)
    XCTAssert(Yaml.load("Null").value! == nil)
    XCTAssert(Yaml.load("NULL").value! == nil)
    XCTAssert(Yaml.load("~").value! == nil)
    XCTAssert(Yaml.load("NuLL").value! == "NuLL")
    XCTAssert(Yaml.load("null#").value! == "null#")
    XCTAssert(Yaml.load("null#string").value! == "null#string")
    XCTAssert(Yaml.load("null #comment").value! == nil)
    
    let value: Yaml = nil
    XCTAssert(value == nil)
  }
  
  func testBool() {
    XCTAssert(Yaml.load("true").value! == .Bool(true))
    XCTAssert(Yaml.load("True").value!.bool == true)
    XCTAssert(Yaml.load("TRUE").value! == true)
    XCTAssert(Yaml.load("trUE").value! == "trUE")
    XCTAssert(Yaml.load("true#").value! == "true#")
    XCTAssert(Yaml.load("true#string").value! == "true#string")
    XCTAssert(Yaml.load("true #comment").value! == true)
    XCTAssert(Yaml.load("true  #").value! == true)
    XCTAssert(Yaml.load("true  ").value! == true)
    XCTAssert(Yaml.load("true\n").value! == true)
    XCTAssert(Yaml.load("true \n").value! == true)
    XCTAssert(true == Yaml.load("\ntrue \n").value!)
    
    XCTAssert(Yaml.load("false").value! == .Bool(false))
    XCTAssert(Yaml.load("False").value!.bool == false)
    XCTAssert(Yaml.load("FALSE").value! == false)
    XCTAssert(Yaml.load("faLSE").value! == "faLSE")
    XCTAssert(Yaml.load("false#").value! == "false#")
    XCTAssert(Yaml.load("false#string").value! == "false#string")
    XCTAssert(Yaml.load("false #comment").value! == false)
    XCTAssert(Yaml.load("false  #").value! == false)
    XCTAssert(Yaml.load("false  ").value! == false)
    XCTAssert(Yaml.load("false\n").value! == false)
    XCTAssert(Yaml.load("false \n").value! == false)
    XCTAssert(false == Yaml.load("\nfalse \n").value!)
    
    let value: Yaml = true
    XCTAssert(value == true)
    XCTAssert(value.bool == true)
  }
  
  func testInt() {
    XCTAssert(Yaml.load("0").value! == .Int(0))
    XCTAssert(Yaml.load("+0").value!.int == 0)
    XCTAssert(Yaml.load("-0").value! == 0)
    XCTAssert(Yaml.load("2").value! == 2)
    XCTAssert(Yaml.load("+2").value! == 2)
    XCTAssert(Yaml.load("-2").value! == -2)
    XCTAssert(Yaml.load("00123").value! == 123)
    XCTAssert(Yaml.load("+00123").value! == 123)
    XCTAssert(Yaml.load("-00123").value! == -123)
    XCTAssert(Yaml.load("0o10").value! == 8)
    XCTAssert(Yaml.load("0o010").value! == 8)
    XCTAssert(Yaml.load("0o0010").value! == 8)
    XCTAssert(Yaml.load("0x10").value! == 16)
    XCTAssert(Yaml.load("0x1a").value! == 26)
    XCTAssert(Yaml.load("0x01a").value! == 26)
    XCTAssert(Yaml.load("0x001a").value! == 26)
    XCTAssert(Yaml.load("10:10").value! == 610)
    XCTAssert(Yaml.load("10:10:10").value! == 36610)
    
    XCTAssert(Yaml.load("2").value! == 2)
    XCTAssert(Yaml.load("2.0").value! == 2)
    XCTAssert(Yaml.load("2.5").value! != 2)
    XCTAssert(Yaml.load("2.5").value!.int == nil)
    
    let value1: Yaml = 2
    XCTAssert(value1 == 2)
    XCTAssert(value1.int == 2)
    let value2: Yaml = -2
    XCTAssert(value2 == -2)
    XCTAssert(-value2 == 2)
    XCTAssert(-value2 == value1)
  }
  
  func testDouble() {
    XCTAssert(Yaml.load(".inf").value! == .Double(Double.infinity))
    XCTAssert(Yaml.load(".Inf").value!.double == Double.infinity)
    XCTAssert(Yaml.load(".INF").value!.double == Double.infinity)
    XCTAssert(Yaml.load(".iNf").value! == ".iNf")
    XCTAssert(Yaml.load(".inf#").value! == ".inf#")
    XCTAssert(Yaml.load(".inf# string").value! == ".inf# string")
    XCTAssert(Yaml.load(".inf # comment").value!.double == Double.infinity)
    XCTAssert(Yaml.load(".inf .inf").value! == ".inf .inf")
    XCTAssert(Yaml.load("+.inf # comment").value!.double == Double.infinity)
    
    XCTAssert(Yaml.load("-.inf").value! == .Double(-Double.infinity))
    XCTAssert(Yaml.load("-.Inf").value!.double == -Double.infinity)
    XCTAssert(Yaml.load("-.INF").value!.double == -Double.infinity)
    XCTAssert(Yaml.load("-.iNf").value! == "-.iNf")
    XCTAssert(Yaml.load("-.inf#").value! == "-.inf#")
    XCTAssert(Yaml.load("-.inf# string").value! == "-.inf# string")
    XCTAssert(Yaml.load("-.inf # comment").value!.double == -Double.infinity)
    XCTAssert(Yaml.load("-.inf -.inf").value! == "-.inf -.inf")
    
    XCTAssert(Yaml.load(".nan").value! != .Double(Double.NaN))
    XCTAssert(Yaml.load(".nan").value!.double!.isNaN)
    XCTAssert(Yaml.load(".NaN").value!.double!.isNaN)
    XCTAssert(Yaml.load(".NAN").value!.double!.isNaN)
    XCTAssert(Yaml.load(".Nan").value!.double == nil)
    XCTAssert(Yaml.load(".nan#").value! == ".nan#")
    XCTAssert(Yaml.load(".nan# string").value! == ".nan# string")
    XCTAssert(Yaml.load(".nan # comment").value!.double!.isNaN)
    XCTAssert(Yaml.load(".nan .nan").value! == ".nan .nan")
    
    XCTAssert(Yaml.load("0.").value! == .Double(0))
    XCTAssert(Yaml.load(".0").value!.double == 0)
    XCTAssert(Yaml.load("+0.").value! == 0)
    XCTAssert(Yaml.load("+.0").value! == 0)
    XCTAssert(Yaml.load("+.").value! != 0)
    XCTAssert(Yaml.load("-0.").value! == 0)
    XCTAssert(Yaml.load("-.0").value! == 0)
    XCTAssert(Yaml.load("-.").value! != 0)
    XCTAssert(Yaml.load("2.").value! == 2)
    XCTAssert(Yaml.load(".2").value! == 0.2)
    XCTAssert(Yaml.load("+2.").value! == 2)
    XCTAssert(Yaml.load("+.2").value! == 0.2)
    XCTAssert(Yaml.load("-2.").value! == -2)
    XCTAssert(Yaml.load("-.2").value! == -0.2)
    XCTAssert(Yaml.load("1.23015e+3").value! == 1.23015e+3)
    XCTAssert(Yaml.load("12.3015e+02").value! == 12.3015e+02)
    XCTAssert(Yaml.load("1230.15").value! == 1230.15)
    XCTAssert(Yaml.load("+1.23015e+3").value! == 1.23015e+3)
    XCTAssert(Yaml.load("+12.3015e+02").value! == 12.3015e+02)
    XCTAssert(Yaml.load("+1230.15").value! == 1230.15)
    XCTAssert(Yaml.load("-1.23015e+3").value! == -1.23015e+3)
    XCTAssert(Yaml.load("-12.3015e+02").value! == -12.3015e+02)
    XCTAssert(Yaml.load("-1230.15").value! == -1230.15)
    XCTAssert(Yaml.load("-01230.15").value! == -1230.15)
    XCTAssert(Yaml.load("-12.3015e02").value! == -12.3015e+02)
    
    XCTAssert(Yaml.load("2").value! == 2.0)
    XCTAssert(Yaml.load("2.0").value! == 2.0)
    XCTAssert(Yaml.load("2.5").value! == 2.5)
    XCTAssert(Yaml.load("2.5").value!.int == nil)
    
    let value1: Yaml = 0.2
    XCTAssert(value1 == 0.2)
    XCTAssert(value1.double == 0.2)
    let value2: Yaml = -0.2
    XCTAssert(value2 == -0.2)
    XCTAssert(-value2 == 0.2)
    XCTAssert(-value2 == value1)
  }
  
  func testString () {
    XCTAssert(Yaml.load("Behrang").value! == .String("Behrang"))
    XCTAssert(Yaml.load("\"Behrang\"").value! == .String("Behrang"))
    XCTAssert(Yaml.load("\"B\\\"ehran\\\"g\"").value! == .String("B\"ehran\"g"))
    XCTAssert(Yaml.load("Behrang Noruzi Niya").value!.string ==
      "Behrang Noruzi Niya")
    XCTAssert(Yaml.load("Radin Noruzi Niya").value! == "Radin Noruzi Niya")
    XCTAssert(Yaml.load("|").value! == "")
    XCTAssert(Yaml.load("| ").value! == "")
    XCTAssert(Yaml.load("|  # comment").value! == "")
    XCTAssert(Yaml.load("|  # comment\n").value! == "")
    XCTAssert(Yaml.load("|\nRadin").error != nil)
    XCTAssert(Yaml.load("|\n Radin").value! == "Radin")
    XCTAssert(Yaml.load("|  \n Radin").value! == "Radin")
    XCTAssert(Yaml.load("|  # comment\n Radin").value! == "Radin")
    XCTAssert(Yaml.load("|\n  Radin").value! == "Radin")
    XCTAssert(Yaml.load("|2\n  Radin").value! == "Radin")
    XCTAssert(Yaml.load("|1\n  Radin").value! == " Radin")
    XCTAssert(Yaml.load("|1\n\n  Radin").value! == "\n Radin")
    XCTAssert(Yaml.load("|\n\n  Radin").value! == "\nRadin")
    XCTAssert(Yaml.load("|3\n\n  Radin").value == nil)
    XCTAssert(Yaml.load("|3\n    \n   Radin").value == nil)
    XCTAssert(Yaml.load("|3\n   \n   Radin").value! == "\nRadin")
    XCTAssert(Yaml.load("|\n  \n\n \n  Radin\n\n \n\n  Noruzi Niya").value! ==
      "\n\n\nRadin\n\n\n\nNoruzi Niya")
    XCTAssert(Yaml.load("|\n  \n\n \n  Radin\n\n \n\n  Noruzi Niya\n  #1").value! ==
      "\n\n\nRadin\n\n\n\nNoruzi Niya\n#1")
    XCTAssert(Yaml.load("|\n  \n\n \n  Radin\n\n \n\n  Noruzi Niya\n  #1" +
      "\n # Comment").value! == "\n\n\nRadin\n\n\n\nNoruzi Niya\n#1\n")
    XCTAssert(Yaml.load("|\n Radin\n").value! == "Radin\n")
    XCTAssert(Yaml.load("|\n Radin\n\n").value! == "Radin\n")
    XCTAssert(Yaml.load("|\n Radin\n \n ").value! == "Radin\n")
    XCTAssert(Yaml.load("|\n Radin\n  \n  ").value! == "Radin\n")
    XCTAssert(Yaml.load("|-\n Radin\n  \n  ").value! == "Radin")
    XCTAssert(Yaml.load("|+\n Radin\n").value! == "Radin\n")
    XCTAssert(Yaml.load("|+\n Radin\n\n").value! == "Radin\n\n")
    XCTAssert(Yaml.load("|+\n Radin\n \n ").value! == "Radin\n\n")
    XCTAssert(Yaml.load("|+\n Radin\n  \n  ").value! == "Radin\n \n ")
    XCTAssert(Yaml.load("|2+\n  Radin\n  \n  ").value! == "Radin\n\n")
    XCTAssert(Yaml.load("|+2\n  Radin\n  \n  ").value! == "Radin\n\n")
    XCTAssert(Yaml.load("|-2\n  Radin\n  \n  ").value! == "Radin")
    XCTAssert(Yaml.load("|2-\n  Radin\n  \n  ").value! == "Radin")
    XCTAssert(Yaml.load("|22\n  Radin\n  \n  ").error != nil)
    XCTAssert(Yaml.load("|--\n  Radin\n  \n  ").error != nil)
    XCTAssert(Yaml.load(">+\n  trimmed\n  \n \n\n  as\n  space\n\n   \n").value! ==
      "trimmed\n\n\nas space\n\n \n")
    XCTAssert(Yaml.load(">-\n  trimmed\n  \n \n\n  as\n  space").value! ==
      "trimmed\n\n\nas space")
    XCTAssert(Yaml.load(">\n  foo \n \n  \t bar\n\n  baz\n").value! ==
      "foo \n\n\t bar\n\nbaz\n")
    
    XCTAssert(Yaml.load(">\n  \n Behrang").error != nil)
    XCTAssert(Yaml.load(">\n  \n  Behrang").value! == "\nBehrang")
    XCTAssert(Yaml.load(">\n\n folded\n line\n\n next\n line\n   * bullet\n\n" +
      "   * list\n   * lines\n\n last\n line\n\n# Comment").value! ==
      .String("\nfolded line\nnext line\n  * bullet\n\n  * list\n  * lines" +
        "\n\nlast line\n"))
    
    XCTAssert(Yaml.load("\"\n  foo \n \n  \t bar\n\n  baz\n\"").value! ==
      " foo\nbar\nbaz ")
    XCTAssert(Yaml.load("\"folded \nto a space,\t\n \nto a line feed," +
      " or \t\\\n \\ \tnon-content\"").value! ==
      "folded to a space,\nto a line feed, or \t \tnon-content")
    XCTAssert(Yaml.load("\" 1st non-empty\n\n 2nd non-empty" +
      " \n\t3rd non-empty \"").value! ==
      " 1st non-empty\n2nd non-empty 3rd non-empty ")
    
    XCTAssert(Yaml.load("'here''s to \"quotes\"'").value! == "here's to \"quotes\"")
    XCTAssert(Yaml.load("' 1st non-empty\n\n 2nd non-empty" +
      " \n\t3rd non-empty '").value! ==
      " 1st non-empty\n2nd non-empty 3rd non-empty ")
    
    XCTAssert(Yaml.load("x\n y\nz").value! == "x y z")
    XCTAssert(Yaml.load(" x\ny\n z").value! == "x y z")
    XCTAssert(Yaml.load("a: x\n y\n  z").value! == ["a": "x y z"])
    XCTAssert(Yaml.load("a: x\ny\n  z").error != nil)
    XCTAssert(Yaml.load("- a: x\n   y\n    z").value! == [["a": "x y z"]])
    XCTAssert(Yaml.load("- a:\n   x\n    y\n   z").value! == [["a": "x y z"]])
    XCTAssert(Yaml.load("- a:     \n   x\n    y\n   z").value! == [["a": "x y z"]])
    XCTAssert(Yaml.load("- a: # comment\n   x\n    y\n   z").value! ==
      [["a": "x y z"]])
    
    let value1: Yaml = "Radin"
    XCTAssert(value1 == "Radin")
    XCTAssert(value1.string == "Radin")
    
    let value2 = Yaml.load(
      "# Outside flow collection:\n" +
        "- ::vector\n" +
        "- \": - ()\"\n" +
        "- Up, up, and away!\n" +
        "- -123\n" +
        "- http://example.com/foo#bar\n" +
        "# Inside flow collection:\n" +
        "- [ ::vector,\n" +
        "  \": - ()\",\n" +
        "  \"Up, up and away!\",\n" +
        "  -123,\n" +
      "  http://example.com/foo#bar ]\n"
      ).value!
    XCTAssert(value2.count == 6)
    XCTAssert(value2[0] == "::vector")
    XCTAssert(value2[5][0] == "::vector")
    XCTAssert(value2[5][4] == "http://example.com/foo#bar")
  }
  
  func testFlowSeq () {
    XCTAssert(Yaml.load("[]").value! == .Array([]))
    XCTAssert(Yaml.load("[]").value!.count == 0)
    XCTAssert(Yaml.load("[ true ]").value! == [Yaml.Bool(true)])
    XCTAssert(Yaml.load("[ true ]").value! == .Array([true]))
    XCTAssert(Yaml.load("[ true ]").value! == [true])
    XCTAssert(Yaml.load("[ true ]").value![0] == true)
    XCTAssert(Yaml.load("[true, false, true]").value! == [true, false, true])
    XCTAssert(Yaml.load("[Behrang, Radin]").value! == ["Behrang", "Radin"])
    XCTAssert(Yaml.load("[true, [false, true]]").value! == [true, [false, true]])
    XCTAssert(Yaml.load("[true, true  ,false,  false  ,  false]").value! ==
      [true, true, false, false, false])
    XCTAssert(Yaml.load("[true, .NaN]").value! != [true, .Double(Double.NaN)])
    XCTAssert(Yaml.load("[~, null, TRUE, False, .INF, -.inf, 0, 123, -456" +
      ", 0o74, 0xFf, 1.23, -4.5]").value! ==
      [nil, nil, true, false,
        .Double(Double.infinity), .Double(-Double.infinity),
        0, 123, -456, 60, 255, 1.23, -4.5])
    XCTAssert(Yaml.load("x:\n y:\n  z: [\n1]").error != nil)
    XCTAssert(Yaml.load("x:\n y:\n  z: [\n  1]").error != nil)
    XCTAssert(Yaml.load("x:\n y:\n  z: [\n   1]").value! == ["x": ["y": ["z": [1]]]])
  }

  func testBlockSeq () {
    XCTAssert(Yaml.load("- 1\n- 2").value! == [1, 2])
    XCTAssert(Yaml.load("- 1\n- 2").value![1] == 2)
    XCTAssert(Yaml.load("- x: 1").value! == [["x": 1]])
    XCTAssert(Yaml.load("- x: 1\n  y: 2").value![0] == ["x": 1, "y": 2])
    XCTAssert(Yaml.load("- 1\n    \n- x: 1\n  y: 2").value! == [1, ["x": 1, "y": 2]])
    XCTAssert(Yaml.load("- x:\n  - y: 1").value! == [["x": [["y": 1]]]])
  }
  
  func testFlowMap () {
    XCTAssert(Yaml.load("{}").value! == [:])
    XCTAssert(Yaml.load("{x: 1}").value! == ["x": 1])
    XCTAssert(Yaml.load("{x: 1, x: 2}").error != nil)
    XCTAssert(Yaml.load("{x: 1}").value!["x"] == 1)
    XCTAssert(Yaml.load("{x:1}").error != nil)
    XCTAssert(Yaml.load("{\"x\":1}").value!["x"] == 1)
    XCTAssert(Yaml.load("{\"x\":1, 'y': true}").value!["y"] == true)
    XCTAssert(Yaml.load("{\"x\":1, 'y': true, z: null}").value!["z"] == nil)
    XCTAssert(Yaml.load("{first name: \"Behrang\"," +
      " last name: 'Noruzi Niya'}").value! ==
      ["first name": "Behrang", "last name": "Noruzi Niya"])
    XCTAssert(Yaml.load("{fn: Behrang, ln: Noruzi Niya}").value!["ln"] ==
      "Noruzi Niya")
    XCTAssert(Yaml.load("{fn: Behrang\n ,\nln: Noruzi Niya}").value!["ln"] ==
      "Noruzi Niya")
  }
  
  func testBlockMap () {
    XCTAssert(Yaml.load("x: 1\ny: 2").value! ==
      .Dictionary([.String("x"): .Int(1), .String("y"): .Int(2)]))
    XCTAssert(Yaml.load("x: 1\nx: 2").error != nil)
    XCTAssert(Yaml.load("x: 1\n? y\n: 2").value! == ["x": 1, "y": 2])
    XCTAssert(Yaml.load("x: 1\n? x\n: 2").error != nil)
    XCTAssert(Yaml.load("x: 1\n?  y\n:\n2").error != nil)
    XCTAssert(Yaml.load("x: 1\n?  y\n:\n 2").value! == ["x": 1, "y": 2])
    XCTAssert(Yaml.load("x: 1\n?  y").value! == ["x": 1, "y": nil])
    XCTAssert(Yaml.load("?  y").value! == ["y": nil])
    XCTAssert(Yaml.load(" \n  \n \n  \n\nx: 1  \n   \ny: 2" +
      "\n   \n  \n ").value!["y"] == 2)
    XCTAssert(Yaml.load("x:\n a: 1 # comment \n b: 2\ny: " +
      "\n  c: 3\n  ").value!["y"]["c"] == 3)
    XCTAssert(Yaml.load("# comment \n\n  # x\n  # y \n  \n  x: 1" +
      "  \n  y: 2").value! == ["x": 1, "y": 2])
  }
  
  func testDirectives () {
    XCTAssert(Yaml.load("%YAML 1.2\n1").error != nil)
    XCTAssert(Yaml.load("%YAML   1.2\n---1").value! == 1)
    XCTAssert(Yaml.load("%YAML   1.2  #\n---1").value! == 1)
    XCTAssert(Yaml.load("%YAML   1.2\n%YAML 1.2\n---1").error != nil)
    XCTAssert(Yaml.load("%YAML 1.0\n---1").error != nil)
    XCTAssert(Yaml.load("%YAML 1\n---1").error != nil)
    XCTAssert(Yaml.load("%YAML 1.3\n---1").error != nil)
    XCTAssert(Yaml.load("%YAML \n---1").error != nil)
  }
  
  func testReserves () {
    XCTAssert(Yaml.load("`reserved").error != nil)
    XCTAssert(Yaml.load("@behrangn").error != nil)
    XCTAssert(Yaml.load("twitter handle: @behrangn").error != nil)
  }
  
  func testAliases () {
    XCTAssert(Yaml.load("x: &a 1\ny: *a").value! == ["x": 1, "y": 1])
    XCTAssert(Yaml.loadMultiple("x: &a 1\ny: *a\n---\nx: *a").error != nil)
    XCTAssert(Yaml.load("x: *a").error != nil)
  }
  
  func testUnicodeSurrogates() {
    XCTAssert(Yaml.load("x: Dog‼🐶\ny: 𝒂𝑡").value! == ["x": "Dog‼🐶", "y": "𝒂𝑡"])
  }
  
}
