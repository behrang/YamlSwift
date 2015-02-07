import Yaml

func null () {
  assert(Yaml.load("# comment line").value! == .Null)
  assert(Yaml.load("").value! == .Null)
  assert(Yaml.load("null").value! == .Null)
  assert(Yaml.load("Null").value! == nil)
  assert(Yaml.load("NULL").value! == nil)
  assert(Yaml.load("~").value! == nil)
  assert(Yaml.load("NuLL").value! == "NuLL")
  assert(Yaml.load("null#").value! == "null#")
  assert(Yaml.load("null#string").value! == "null#string")
  assert(Yaml.load("null #comment").value! == nil)

  let value: Yaml = nil
  assert(value == nil)
}

func bool () {
  assert(Yaml.load("true").value! == .Bool(true))
  assert(Yaml.load("True").value!.bool == true)
  assert(Yaml.load("TRUE").value! == true)
  assert(Yaml.load("trUE").value! == "trUE")
  assert(Yaml.load("true#").value! == "true#")
  assert(Yaml.load("true#string").value! == "true#string")
  assert(Yaml.load("true #comment").value! == true)
  assert(Yaml.load("true  #").value! == true)
  assert(Yaml.load("true  ").value! == true)
  assert(Yaml.load("true\n").value! == true)
  assert(Yaml.load("true \n").value! == true)
  assert(true == Yaml.load("\ntrue \n").value!)

  assert(Yaml.load("false").value! == .Bool(false))
  assert(Yaml.load("False").value!.bool == false)
  assert(Yaml.load("FALSE").value! == false)
  assert(Yaml.load("faLSE").value! == "faLSE")
  assert(Yaml.load("false#").value! == "false#")
  assert(Yaml.load("false#string").value! == "false#string")
  assert(Yaml.load("false #comment").value! == false)
  assert(Yaml.load("false  #").value! == false)
  assert(Yaml.load("false  ").value! == false)
  assert(Yaml.load("false\n").value! == false)
  assert(Yaml.load("false \n").value! == false)
  assert(false == Yaml.load("\nfalse \n").value!)

  let value: Yaml = true
  assert(value == true)
  assert(value.bool == true)
}

func int () {
  assert(Yaml.load("0").value! == .Int(0))
  assert(Yaml.load("+0").value!.int == 0)
  assert(Yaml.load("-0").value! == 0)
  assert(Yaml.load("2").value! == 2)
  assert(Yaml.load("+2").value! == 2)
  assert(Yaml.load("-2").value! == -2)
  assert(Yaml.load("00123").value! == 123)
  assert(Yaml.load("+00123").value! == 123)
  assert(Yaml.load("-00123").value! == -123)
  assert(Yaml.load("0o10").value! == 8)
  assert(Yaml.load("0o010").value! == 8)
  assert(Yaml.load("0o0010").value! == 8)
  assert(Yaml.load("0x10").value! == 16)
  assert(Yaml.load("0x1a").value! == 26)
  assert(Yaml.load("0x01a").value! == 26)
  assert(Yaml.load("0x001a").value! == 26)
  assert(Yaml.load("10:10").value! == 610)
  assert(Yaml.load("10:10:10").value! == 36610)

  assert(Yaml.load("2").value! == 2)
  assert(Yaml.load("2.0").value! == 2)
  assert(Yaml.load("2.5").value! != 2)
  assert(Yaml.load("2.5").value!.int == nil)

  let value1: Yaml = 2
  assert(value1 == 2)
  assert(value1.int == 2)
  let value2: Yaml = -2
  assert(value2 == -2)
  assert(-value2 == 2)
  assert(-value2 == value1)
}

func double () {
  assert(Yaml.load(".inf").value! == .Double(Double.infinity))
  assert(Yaml.load(".Inf").value!.double == Double.infinity)
  assert(Yaml.load(".INF").value!.double == Double.infinity)
  assert(Yaml.load(".iNf").value! == ".iNf")
  assert(Yaml.load(".inf#").value! == ".inf#")
  assert(Yaml.load(".inf# string").value! == ".inf# string")
  assert(Yaml.load(".inf # comment").value!.double == Double.infinity)
  assert(Yaml.load(".inf .inf").value! == ".inf .inf")
  assert(Yaml.load("+.inf # comment").value!.double == Double.infinity)

  assert(Yaml.load("-.inf").value! == .Double(-Double.infinity))
  assert(Yaml.load("-.Inf").value!.double == -Double.infinity)
  assert(Yaml.load("-.INF").value!.double == -Double.infinity)
  assert(Yaml.load("-.iNf").value! == "-.iNf")
  assert(Yaml.load("-.inf#").value! == "-.inf#")
  assert(Yaml.load("-.inf# string").value! == "-.inf# string")
  assert(Yaml.load("-.inf # comment").value!.double == -Double.infinity)
  assert(Yaml.load("-.inf -.inf").value! == "-.inf -.inf")

  assert(Yaml.load(".nan").value! != .Double(Double.NaN))
  assert(Yaml.load(".nan").value!.double!.isNaN)
  assert(Yaml.load(".NaN").value!.double!.isNaN)
  assert(Yaml.load(".NAN").value!.double!.isNaN)
  assert(Yaml.load(".Nan").value!.double == nil)
  assert(Yaml.load(".nan#").value! == ".nan#")
  assert(Yaml.load(".nan# string").value! == ".nan# string")
  assert(Yaml.load(".nan # comment").value!.double!.isNaN)
  assert(Yaml.load(".nan .nan").value! == ".nan .nan")

  assert(Yaml.load("0.").value! == .Double(0))
  assert(Yaml.load(".0").value!.double == 0)
  assert(Yaml.load("+0.").value! == 0)
  assert(Yaml.load("+.0").value! == 0)
  assert(Yaml.load("+.").value! != 0)
  assert(Yaml.load("-0.").value! == 0)
  assert(Yaml.load("-.0").value! == 0)
  assert(Yaml.load("-.").value! != 0)
  assert(Yaml.load("2.").value! == 2)
  assert(Yaml.load(".2").value! == 0.2)
  assert(Yaml.load("+2.").value! == 2)
  assert(Yaml.load("+.2").value! == 0.2)
  assert(Yaml.load("-2.").value! == -2)
  assert(Yaml.load("-.2").value! == -0.2)
  assert(Yaml.load("1.23015e+3").value! == 1.23015e+3)
  assert(Yaml.load("12.3015e+02").value! == 12.3015e+02)
  assert(Yaml.load("1230.15").value! == 1230.15)
  assert(Yaml.load("+1.23015e+3").value! == 1.23015e+3)
  assert(Yaml.load("+12.3015e+02").value! == 12.3015e+02)
  assert(Yaml.load("+1230.15").value! == 1230.15)
  assert(Yaml.load("-1.23015e+3").value! == -1.23015e+3)
  assert(Yaml.load("-12.3015e+02").value! == -12.3015e+02)
  assert(Yaml.load("-1230.15").value! == -1230.15)
  assert(Yaml.load("-01230.15").value! == -1230.15)
  assert(Yaml.load("-12.3015e02").value! == -12.3015e+02)

  assert(Yaml.load("2").value! == 2.0)
  assert(Yaml.load("2.0").value! == 2.0)
  assert(Yaml.load("2.5").value! == 2.5)
  assert(Yaml.load("2.5").value!.int == nil)

  let value1: Yaml = 0.2
  assert(value1 == 0.2)
  assert(value1.double == 0.2)
  let value2: Yaml = -0.2
  assert(value2 == -0.2)
  assert(-value2 == 0.2)
  assert(-value2 == value1)
}

func string () {
  assert(Yaml.load("Behrang").value! == .String("Behrang"))
  assert(Yaml.load("\"Behrang\"").value! == .String("Behrang"))
  assert(Yaml.load("\"B\\\"ehran\\\"g\"").value! == .String("B\"ehran\"g"))
  assert(Yaml.load("Behrang Noruzi Niya").value!.string ==
      "Behrang Noruzi Niya")
  assert(Yaml.load("Radin Noruzi Niya").value! == "Radin Noruzi Niya")
  assert(Yaml.load("|").value! == "")
  assert(Yaml.load("| ").value! == "")
  assert(Yaml.load("|  # comment").value! == "")
  assert(Yaml.load("|  # comment\n").value! == "")
  assert(Yaml.load("|\nRadin").error != nil)
  assert(Yaml.load("|\n Radin").value! == "Radin")
  assert(Yaml.load("|  \n Radin").value! == "Radin")
  assert(Yaml.load("|  # comment\n Radin").value! == "Radin")
  assert(Yaml.load("|\n  Radin").value! == "Radin")
  assert(Yaml.load("|2\n  Radin").value! == "Radin")
  assert(Yaml.load("|1\n  Radin").value! == " Radin")
  assert(Yaml.load("|1\n\n  Radin").value! == "\n Radin")
  assert(Yaml.load("|\n\n  Radin").value! == "\nRadin")
  assert(Yaml.load("|3\n\n  Radin").value == nil)
  assert(Yaml.load("|3\n    \n   Radin").value == nil)
  assert(Yaml.load("|3\n   \n   Radin").value! == "\nRadin")
  assert(Yaml.load("|\n  \n\n \n  Radin\n\n \n\n  Noruzi Niya").value! ==
      "\n\n\nRadin\n\n\n\nNoruzi Niya")
  assert(Yaml.load("|\n  \n\n \n  Radin\n\n \n\n  Noruzi Niya\n  #1").value! ==
      "\n\n\nRadin\n\n\n\nNoruzi Niya\n#1")
  assert(Yaml.load("|\n  \n\n \n  Radin\n\n \n\n  Noruzi Niya\n  #1" +
      "\n # Comment").value! == "\n\n\nRadin\n\n\n\nNoruzi Niya\n#1\n")
  assert(Yaml.load("|\n Radin\n").value! == "Radin\n")
  assert(Yaml.load("|\n Radin\n\n").value! == "Radin\n")
  assert(Yaml.load("|\n Radin\n \n ").value! == "Radin\n")
  assert(Yaml.load("|\n Radin\n  \n  ").value! == "Radin\n")
  assert(Yaml.load("|-\n Radin\n  \n  ").value! == "Radin")
  assert(Yaml.load("|+\n Radin\n").value! == "Radin\n")
  assert(Yaml.load("|+\n Radin\n\n").value! == "Radin\n\n")
  assert(Yaml.load("|+\n Radin\n \n ").value! == "Radin\n\n")
  assert(Yaml.load("|+\n Radin\n  \n  ").value! == "Radin\n \n ")
  assert(Yaml.load("|2+\n  Radin\n  \n  ").value! == "Radin\n\n")
  assert(Yaml.load("|+2\n  Radin\n  \n  ").value! == "Radin\n\n")
  assert(Yaml.load("|-2\n  Radin\n  \n  ").value! == "Radin")
  assert(Yaml.load("|2-\n  Radin\n  \n  ").value! == "Radin")
  assert(Yaml.load("|22\n  Radin\n  \n  ").error != nil)
  assert(Yaml.load("|--\n  Radin\n  \n  ").error != nil)
  assert(Yaml.load(">+\n  trimmed\n  \n \n\n  as\n  space\n\n   \n").value! ==
      "trimmed\n\n\nas space\n\n \n")
  assert(Yaml.load(">-\n  trimmed\n  \n \n\n  as\n  space").value! ==
      "trimmed\n\n\nas space")
  assert(Yaml.load(">\n  foo \n \n  \t bar\n\n  baz\n").value! ==
      "foo \n\n\t bar\n\nbaz\n")

  assert(Yaml.load(">\n  \n Behrang").error != nil)
  assert(Yaml.load(">\n  \n  Behrang").value! == "\nBehrang")
  assert(Yaml.load(">\n\n folded\n line\n\n next\n line\n   * bullet\n\n" +
      "   * list\n   * lines\n\n last\n line\n\n# Comment").value! ==
      .String("\nfolded line\nnext line\n  * bullet\n\n  * list\n  * lines" +
      "\n\nlast line\n"))

  assert(Yaml.load("\"\n  foo \n \n  \t bar\n\n  baz\n\"").value! ==
      " foo\nbar\nbaz ")
  assert(Yaml.load("\"folded \nto a space,\t\n \nto a line feed," +
      " or \t\\\n \\ \tnon-content\"").value! ==
      "folded to a space,\nto a line feed, or \t \tnon-content")
  assert(Yaml.load("\" 1st non-empty\n\n 2nd non-empty" +
      " \n\t3rd non-empty \"").value! ==
      " 1st non-empty\n2nd non-empty 3rd non-empty ")

  assert(Yaml.load("'here''s to \"quotes\"'").value! == "here's to \"quotes\"")
  assert(Yaml.load("' 1st non-empty\n\n 2nd non-empty" +
      " \n\t3rd non-empty '").value! ==
      " 1st non-empty\n2nd non-empty 3rd non-empty ")

  assert(Yaml.load("x\n y\nz").value! == "x y z")
  assert(Yaml.load(" x\ny\n z").value! == "x y z")
  assert(Yaml.load("a: x\n y\n  z").value! == ["a": "x y z"])
  assert(Yaml.load("a: x\ny\n  z").error != nil)
  assert(Yaml.load("- a: x\n   y\n    z").value! == [["a": "x y z"]])
  assert(Yaml.load("- a:\n   x\n    y\n   z").value! == [["a": "x y z"]])
  assert(Yaml.load("- a:     \n   x\n    y\n   z").value! == [["a": "x y z"]])
  assert(Yaml.load("- a: # comment\n   x\n    y\n   z").value! ==
      [["a": "x y z"]])

  let value1: Yaml = "Radin"
  assert(value1 == "Radin")
  assert(value1.string == "Radin")

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
  assert(value2.count == 6)
  assert(value2[0] == "::vector")
  assert(value2[5][0] == "::vector")
  assert(value2[5][4] == "http://example.com/foo#bar")
}

func flowSeq () {
  assert(Yaml.load("[]").value! == .Array([]))
  assert(Yaml.load("[]").value!.count == 0)
  assert(Yaml.load("[ true ]").value! == [Yaml.Bool(true)])
  assert(Yaml.load("[ true ]").value! == .Array([true]))
  assert(Yaml.load("[ true ]").value! == [true])
  assert(Yaml.load("[ true ]").value![0] == true)
  assert(Yaml.load("[true, false, true]").value! == [true, false, true])
  assert(Yaml.load("[Behrang, Radin]").value! == ["Behrang", "Radin"])
  assert(Yaml.load("[true, [false, true]]").value! == [true, [false, true]])
  assert(Yaml.load("[true, true  ,false,  false  ,  false]").value! ==
      [true, true, false, false, false])
  assert(Yaml.load("[true, .NaN]").value! != [true, .Double(Double.NaN)])
  assert(Yaml.load("[~, null, TRUE, False, .INF, -.inf, 0, 123, -456" +
      ", 0o74, 0xFf, 1.23, -4.5]").value! ==
      [nil, nil, true, false,
          .Double(Double.infinity), .Double(-Double.infinity),
          0, 123, -456, 60, 255, 1.23, -4.5])
  assert(Yaml.load("x:\n y:\n  z: [\n1]").error != nil)
  assert(Yaml.load("x:\n y:\n  z: [\n  1]").error != nil)
  assert(Yaml.load("x:\n y:\n  z: [\n   1]").value! == ["x": ["y": ["z": [1]]]])
}

func blockSeq () {
  assert(Yaml.load("- 1\n- 2").value! == [1, 2])
  assert(Yaml.load("- 1\n- 2").value![1] == 2)
  assert(Yaml.load("- x: 1").value! == [["x": 1]])
  assert(Yaml.load("- x: 1\n  y: 2").value![0] == ["x": 1, "y": 2])
  assert(Yaml.load("- 1\n    \n- x: 1\n  y: 2").value! == [1, ["x": 1, "y": 2]])
  assert(Yaml.load("- x:\n  - y: 1").value! == [["x": [["y": 1]]]])
}

func flowMap () {
  assert(Yaml.load("{}").value! == [:])
  assert(Yaml.load("{x: 1}").value! == ["x": 1])
  assert(Yaml.load("{x: 1, x: 2}").error != nil)
  assert(Yaml.load("{x: 1}").value!["x"] == 1)
  assert(Yaml.load("{x:1}").error != nil)
  assert(Yaml.load("{\"x\":1}").value!["x"] == 1)
  assert(Yaml.load("{\"x\":1, 'y': true}").value!["y"] == true)
  assert(Yaml.load("{\"x\":1, 'y': true, z: null}").value!["z"] == nil)
  assert(Yaml.load("{first name: \"Behrang\"," +
      " last name: 'Noruzi Niya'}").value! ==
      ["first name": "Behrang", "last name": "Noruzi Niya"])
  assert(Yaml.load("{fn: Behrang, ln: Noruzi Niya}").value!["ln"] ==
      "Noruzi Niya")
  assert(Yaml.load("{fn: Behrang\n ,\nln: Noruzi Niya}").value!["ln"] ==
      "Noruzi Niya")
}

func blockMap () {
  assert(Yaml.load("x: 1\ny: 2").value! ==
      .Dictionary([.String("x"): .Int(1), .String("y"): .Int(2)]))
  assert(Yaml.load("x: 1\nx: 2").error != nil)
  assert(Yaml.load("x: 1\n? y\n: 2").value! == ["x": 1, "y": 2])
  assert(Yaml.load("x: 1\n? x\n: 2").error != nil)
  assert(Yaml.load("x: 1\n?  y\n:\n2").error != nil)
  assert(Yaml.load("x: 1\n?  y\n:\n 2").value! == ["x": 1, "y": 2])
  assert(Yaml.load("x: 1\n?  y").value! == ["x": 1, "y": nil])
  assert(Yaml.load("?  y").value! == ["y": nil])
  assert(Yaml.load(" \n  \n \n  \n\nx: 1  \n   \ny: 2" +
      "\n   \n  \n ").value!["y"] == 2)
  assert(Yaml.load("x:\n a: 1 # comment \n b: 2\ny: " +
      "\n  c: 3\n  ").value!["y"]["c"] == 3)
  assert(Yaml.load("# comment \n\n  # x\n  # y \n  \n  x: 1" +
      "  \n  y: 2").value! == ["x": 1, "y": 2])
}

func directives () {
  assert(Yaml.load("%YAML 1.2\n1").error != nil)
  assert(Yaml.load("%YAML   1.2\n---1").value! == 1)
  assert(Yaml.load("%YAML   1.2  #\n---1").value! == 1)
  assert(Yaml.load("%YAML   1.2\n%YAML 1.2\n---1").error != nil)
  assert(Yaml.load("%YAML 1.0\n---1").error != nil)
  assert(Yaml.load("%YAML 1\n---1").error != nil)
  assert(Yaml.load("%YAML 1.3\n---1").error != nil)
  assert(Yaml.load("%YAML \n---1").error != nil)
}

func reserves () {
  assert(Yaml.load("`reserved").error != nil)
  assert(Yaml.load("@behrangn").error != nil)
  assert(Yaml.load("twitter handle: @behrangn").error != nil)
}

func aliases () {
  assert(Yaml.load("x: &a 1\ny: *a").value! == ["x": 1, "y": 1])
  assert(Yaml.loadMultiple("x: &a 1\ny: *a\n---\nx: *a").error != nil)
  assert(Yaml.load("x: *a").error != nil)
}

func unicodeSurrogates() {
  assert(Yaml.load("x: Dog‼🐶\ny: 𝒂𝑡").value! == ["x": "Dog‼🐶", "y": "𝒂𝑡"])
}

func example0 () {
  var value = Yaml.load(
    "- just: write some\n" +
    "- yaml: \n" +
    "  - [here, and]\n" +
    "  - {it: updates, in: real-time}\n"
  ).value!
  assert(value.count == 2)
  assert(value[0]["just"] == "write some")
  assert(value[1]["yaml"][0][1] == "and")
  assert(value[1]["yaml"][1]["in"] == "real-time")

  value[0]["just"] = .String("replaced string")
  assert(value[0]["just"] == "replaced string")
  value[0]["another"] = .Int(2)
  assert(value[0]["another"] == 2)
  value[0]["new"]["key"][10]["key"] = .String("Ten")
  assert(value[0]["new"]["key"][10]["key"] == "Ten")
  value[0]["new"]["key"][5]["key"] = .String("Five")
  assert(value[0]["new"]["key"][5]["key"] == "Five")
  value[0]["new"]["key"][15]["key"] = .String("Fifteen")
  assert(value[0]["new"]["key"][15]["key"] == "Fifteen")
  value[2] = .Double(2)
  assert(value[2] == 2)
  value = nil
  assert(value == nil)
}

func example1 () {
  let value = Yaml.load(
    "- Mark McGwire\n" +
    "- Sammy Sosa\n" +
    "- Ken Griffey\n"
  ).value!
  assert(value.count == 3)
  assert(value[1] == "Sammy Sosa")
}

func example2 () {
  let value = Yaml.load(
    "hr:  65    # Home runs\n" +
    "avg: 0.278 # Batting average\n" +
    "rbi: 147   # Runs Batted In\n"
  ).value!
  assert(value.count == 3)
  assert(value["avg"] == 0.278)
}

func example3 () {
  let value = Yaml.load(
    "american:\n" +
    "  - Boston Red Sox\n" +
    "  - Detroit Tigers\n" +
    "  - New York Yankees\n" +
    "national:\n" +
    "  - New York Mets\n" +
    "  - Chicago Cubs\n" +
    "  - Atlanta Braves\n"
  ).value!
  assert(value.count == 2)
  assert(value["national"].count == 3)
  assert(value["national"][2] == "Atlanta Braves")
}

func example4 () {
  let value = Yaml.load(
    "-\n" +
    "  name: Mark McGwire\n" +
    "  hr:   65\n" +
    "  avg:  0.278\n" +
    "-\n" +
    "  name: Sammy Sosa\n" +
    "  hr:   63\n" +
    "  avg:  0.288\n"
  ).value!
  assert(value.count == 2)
  assert(value[1]["avg"] == 0.288)
}

func example5 () {
  let value = Yaml.load(
    "- [name        , hr, avg  ]\n" +
    "- [Mark McGwire, 65, 0.278]\n" +
    "- [Sammy Sosa  , 63, 0.288]\n"
  ).value!
  assert(value.count == 3)
  assert(value[2].count == 3)
  assert(value[2][2] == 0.288)
}

func example6 () {
  let value = Yaml.load(
    "Mark McGwire: {hr: 65, avg: 0.278}\n" +
    "Sammy Sosa: {\n" +
    "    hr: 63,\n" +
    "    avg: 0.288\n" +
    "  }\n"
  ).value!
  assert(value["Mark McGwire"]["hr"] == 65)
  assert(value["Sammy Sosa"]["hr"] == 63)
}

func example7 () {
  let value = Yaml.loadMultiple(
    "# Ranking of 1998 home runs\n" +
    "---\n" +
    "- Mark McGwire\n" +
    "- Sammy Sosa\n" +
    "- Ken Griffey\n" +
    "\n" +
    "# Team ranking\n" +
    "---\n" +
    "- Chicago Cubs\n" +
    "- St Louis Cardinals\n"
  ).value!
  assert(value.count == 2)
  assert(value[0].count == 3)
  assert(value[0][1] == "Sammy Sosa")
  assert(value[1].count == 2)
  assert(value[1][1] == "St Louis Cardinals")
}

func example8 () {
  let value = Yaml.loadMultiple(
    "---\n" +
    "time: 20:03:20\n" +
    "player: Sammy Sosa\n" +
    "action: strike (miss)\n" +
    "...\n" +
    "---\n" +
    "time: 20:03:47\n" +
    "player: Sammy Sosa\n" +
    "action: grand slam\n" +
    "...\n"
  ).value!
  assert(value.count == 2)
  assert(value[0]["player"] == "Sammy Sosa")
  assert(value[0]["time"] == 72200)
  assert(value[1]["player"] == "Sammy Sosa")
  assert(value[1]["time"] == 72227)
}

func example9 () {
  let value = Yaml.load(
    "---\n" +
    "hr: # 1998 hr ranking\n" +
    "  - Mark McGwire\n" +
    "  - Sammy Sosa\n" +
    "rbi:\n" +
    "  # 1998 rbi ranking\n" +
    "  - Sammy Sosa\n" +
    "  - Ken Griffey\n"
  ).value!
  assert(value["hr"][1] == "Sammy Sosa")
  assert(value["rbi"][1] == "Ken Griffey")
}

func example10 () {
  let value = Yaml.load(
    "---\n" +
    "hr:\n" +
    "  - Mark McGwire\n" +
    "  # Following node labeled SS\n" +
    "  - &SS Sammy Sosa\n" +
    "rbi:\n" +
    "  - *SS # Subsequent occurrence\n" +
    "  - Ken Griffey\n"
  ).value!
  assert(value["hr"].count == 2)
  assert(value["hr"][1] == "Sammy Sosa")
  assert(value["rbi"].count == 2)
  assert(value["rbi"][0] == "Sammy Sosa")
}

func example11 () {
  let value = Yaml.load(
    "? - Detroit Tigers\n" +
    "  - Chicago cubs\n" +
    ":\n" +
    "  - 2001-07-23\n" +
    "\n" +
    "? [ New York Yankees,\n" +
    "    Atlanta Braves ]\n" +
    ": [ 2001-07-02, 2001-08-12,\n" +
    "    2001-08-14 ]\n"
  ).value!
  let key1 = Yaml.load("- Detroit Tigers\n- Chicago cubs\n").value!
  let key2 = Yaml.load("- New York Yankees\n- Atlanta Braves").value!
  assert(value.count == 2)
  assert(value[key1].count == 1)
  assert(value[key2].count == 3)
  assert(value[key2][2] == "2001-08-14")
}

func example12 () {
  let value = Yaml.load(
    "---\n" +
    "# Products purchased\n" +
    "- item    : Super Hoop\n" +
    "  quantity: 1\n" +
    "- item    : Basketball\n" +
    "  quantity: 4\n" +
    "- item    : Big Shoes\n" +
    "  quantity: 1\n"
  ).value!
  assert(value.count == 3)
  assert(value[1].count == 2)
  assert(value[1]["item"] == "Basketball")
  assert(value[1]["quantity"] == 4)
  let key = Yaml.load("quantity").value!
  assert(value[2][key] == 1)
}

func example13 () {
  let value = Yaml.load(
    "# ASCII Art\n" +
    "--- |\n" +
    "  \\//||\\/||\n" +
    "  // ||  ||__\n"
  ).value!
  assert(value == "\\//||\\/||\n// ||  ||__\n")
}

func example14 () {
  let value = Yaml.load(
    "--- >\n" +
    "  Mark McGwire's\n" +
    "  year was crippled\n" +
    "  by a knee injury.\n"
  ).value!
  assert(value == "Mark McGwire's year was crippled by a knee injury.\n")
}

func example15 () {
  let value = Yaml.load(
    ">\n" +
    " Sammy Sosa completed another\n" +
    " fine season with great stats.\n" +
    "\n" +
    "   63 Home Runs\n" +
    "   0.288 Batting Average\n" +
    "\n" +
    " What a year!\n"
  ).value!
  assert(value ==
      .String("Sammy Sosa completed another fine season with great stats.\n\n" +
      "  63 Home Runs\n  0.288 Batting Average\n\nWhat a year!\n"))
}

func example16 () {
  let value = Yaml.load(
    "name: Mark McGwire\n" +
    "accomplishment: >\n" +
    "  Mark set a major league\n" +
    "  home run record in 1998.\n" +
    "stats: |\n" +
    "  65 Home Runs\n" +
    "  0.278 Batting Average\n"
  ).value!
  assert(value["accomplishment"] ==
      "Mark set a major league home run record in 1998.\n")
  assert(value["stats"] == "65 Home Runs\n0.278 Batting Average\n")
}

func example17 () {
  let value = Yaml.load(
    "unicode: \"Sosa did fine.\\u263A\"\n" +
    "control: \"\\b1998\\t1999\\t2000\\n\"\n" +
    "hex esc: \"\\x0d\\x0a is \\r\\n\"\n" +
    "\n" +
    "single: '\"Howdy!\" he cried.'\n" +
    "quoted: ' # Not a ''comment''.'\n" +
    "tie-fighter: '|\\-*-/|'\n"
  ).value!
  assert(value["unicode"] == "Sosa did fine.\u{263A}")
  assert(value["control"] == "\u{8}1998\t1999\t2000\n")
  assert(value["hex esc"] == "\u{d}\u{a} is \r\n")
  assert(value["single"] == "\"Howdy!\" he cried.")
  assert(value["quoted"] == " # Not a 'comment'.")
  assert(value["tie-fighter"] == "|\\-*-/|")
}

func example18 () {
  let value = Yaml.load(
    "plain:\n" +
    "  This unquoted scalar\n" +
    "  spans many lines.\n" +
    "\n" +
    "quoted: \"So does this\n" +
    "  quoted scalar.\\n\"\n"
  ).value!
  assert(value.count == 2)
  assert(value["plain"] == "This unquoted scalar spans many lines.")
  assert(value["quoted"] == "So does this quoted scalar.\n")
}

func example19 () {
  let value = Yaml.load(
    "canonical: 12345\n" +
    "decimal: +12345\n" +
    "octal: 0o14\n" +
    "hexadecimal: 0xC\n"
  ).value!
  assert(value.count == 4)
  assert(value["canonical"] == 12345)
  assert(value["decimal"] == 12345)
  assert(value["octal"] == 12)
  assert(value["hexadecimal"] == 12)
}

func example20 () {
  let value = Yaml.load(
    "canonical: 1.23015e+3\n" +
    "exponential: 12.3015e+02\n" +
    "fixed: 1230.15\n" +
    "negative infinity: -.inf\n" +
    "not a number: .NaN\n"
  ).value!
  assert(value.count == 5)
  assert(value["canonical"] == 1.23015e+3)
  assert(value["exponential"] == 1.23015e+3)
  assert(value["fixed"] == 1.23015e+3)
  assert(value["negative infinity"] == .Double(-Double.infinity))
  assert(value["not a number"].double?.isNaN == true)
}

func example21 () {
  let value = Yaml.load(
    "null:\n" +
    "booleans: [ true, false ]\n" +
    "string: '012345'\n"
  ).value!
  assert(value.count == 3)
  assert(value["null"] == nil)
  assert(value["booleans"] == [true, false])
  assert(value["string"] == "012345")
}

func example22 () {
  let value = Yaml.load(
    "canonical: 2001-12-15T02:59:43.1Z\n" +
    "iso8601: 2001-12-14t21:59:43.10-05:00\n" +
    "spaced: 2001-12-14 21:59:43.10 -5\n" +
    "date: 2002-12-14\n"
  ).value!
  assert(value.count == 4)
  assert(value["canonical"] == "2001-12-15T02:59:43.1Z")
  assert(value["iso8601"] == "2001-12-14t21:59:43.10-05:00")
  assert(value["spaced"] == "2001-12-14 21:59:43.10 -5")
  assert(value["date"] == "2002-12-14")
}

func examples () {
  example0()
  example1()
  example2()
  example3()
  example4()
  example5()
  example6()
  example7()
  example8()
  example9()
  example10()
  example11()
  example12()
  example13()
  example14()
  example15()
  example16()
  example17()
  example18()
  example19()
  example20()
  example21()
  example22()
}

func yamlHomepage () {
  let value = Yaml.load(
    "%YAML 1.2\n" +
    "---\n" +
    "YAML: YAML Ain't Markup Language\n" +
    "\n" +
    "What It Is: YAML is a human friendly data serialization\n" +
    "  standard for all programming languages.\n" +
    "\n" +
    "YAML Resources:\n" +
    "  YAML 1.2 (3rd Edition): http://yaml.org/spec/1.2/spec.html\n" +
    "  YAML 1.1 (2nd Edition): http://yaml.org/spec/1.1/\n" +
    "  YAML 1.0 (1st Edition): http://yaml.org/spec/1.0/\n" +
    "  YAML Issues Page: https://github.com/yaml/yaml/issues\n" +
    "  YAML Mailing List: yaml-core@lists.sourceforge.net\n" +
    "  YAML IRC Channel: \"#yaml on irc.freenode.net\"\n" +
    "  YAML Cookbook (Ruby): http://yaml4r.sourceforge.net/cookbook/\n" +
    "  YAML Reference Parser: http://yaml.org/ypaste/\n" +
    "\n" +
    "Projects:\n" +
    "  C/C++ Libraries:\n" +
    "  - libyaml       # \"C\" Fast YAML 1.1\n" +
    "  - Syck          # (dated) \"C\" YAML 1.0\n" +
    "  - yaml-cpp      # C++ YAML 1.2 implementation\n" +
    "  Ruby:\n" +
    "  - psych         # libyaml wrapper (in Ruby core for 1.9.2)\n" +
    "  - RbYaml        # YAML 1.1 (PyYaml Port)\n" +
    "  - yaml4r        # YAML 1.0, standard library syck binding\n" +
    "  Python:\n" +
    "  - PyYaml        # YAML 1.1, pure python and libyaml binding\n" +
    "  - PySyck        # YAML 1.0, syck binding\n" +
    "  Java:\n" +
    "  - JvYaml        # Java port of RbYaml\n" +
    "  - SnakeYAML     # Java 5 / YAML 1.1\n" +
    "  - YamlBeans     # To/from JavaBeans\n" +
    "  - JYaml         # Original Java Implementation\n" +
    "  Perl Modules:\n" +
    "  - YAML          # Pure Perl YAML Module\n" +
    "  - YAML::XS      # Binding to libyaml\n" +
    "  - YAML::Syck    # Binding to libsyck\n" +
    "  - YAML::Tiny    # A small YAML subset module\n" +
    "  - PlYaml        # Perl port of PyYaml\n" +
    "  C#/.NET:\n" +
    "  - yaml-net      # YAML 1.1 library\n" +
    "  - yatools.net   # (in-progress) YAML 1.1 implementation\n" +
    "  PHP:\n" +
    "  - php-yaml      # libyaml bindings (YAML 1.1)\n" +
    "  - syck          # syck bindings (YAML 1.0)\n" +
    "  - spyc          # yaml loader/dumper (YAML 1.?)\n" +
    "  OCaml:\n" +
    "  - ocaml-syck    # YAML 1.0 via syck bindings\n" +
    "  Javascript:\n" +
    "  - JS-YAML       # Native PyYAML port to JavaScript.\n" +
    "  - JS-YAML Online# Browserified JS-YAML demo, to play with YAML.\n" +
    "  Actionscript:\n" +
    "  - as3yaml       # port of JvYAML (1.1)\n" +
    "  Haskell:\n" +
    "  - YamlReference # Haskell 1.2 reference parser\n" +
    "  Others:\n" +
    "  - yamlvim (src) # YAML dumper/emitter in pure vimscript\n" +
    "\n" +
    "Related Projects:\n" +
    "  - Rx            # Multi-Language Schemata Tool for JSON/YAML\n" +
    "  - Kwalify       # Ruby Schemata Tool for JSON/YAML\n" +
    "  - yaml_vim      # vim syntax files for YAML\n" +
    "  - yatools.net   # Visual Studio editor for YAML\n" +
    "  - JSON          # Official JSON Website\n" +
    "  - Pygments      # Python language Syntax Colorizer /w YAML support\n" +
    "\n" +
    "News:\n" +
    "  - 20-NOV-2011 -- JS-YAML, a JavaScript YAML parser.\n" +
    "  - 18-AUG-2010 -- Ruby 1.9.2 includes psych, a libyaml wrapper.\n" +
    "# Maintained by Clark C. Evans\n" +
    "...\n"
  ).value!
  assert(value.count == 6)
  assert(value["YAML"] == "YAML Ain't Markup Language")
  assert(value["What It Is"] == .String("YAML is a human friendly data" +
      " serialization standard for all programming languages."))
  assert(value["YAML Resources"].count == 8)
  assert(value["YAML Resources"]["YAML 1.2 (3rd Edition)"] ==
      "http://yaml.org/spec/1.2/spec.html")
  assert(value["YAML Resources"]["YAML IRC Channel"] ==
      "#yaml on irc.freenode.net")
  assert(value["Projects"].count == 12)
  assert(value["Projects"]["C/C++ Libraries"][2] == "yaml-cpp")
  assert(value["Projects"]["Perl Modules"].count == 5)
  assert(value["Projects"]["Perl Modules"][0] == "YAML")
  assert(value["Projects"]["Perl Modules"][1] == "YAML::XS")
  assert(value["Related Projects"].count == 6)
  assert(value["News"].count == 2)
}

func test () {
  null()
  bool()
  int()
  double()
  string()

  flowSeq()
  blockSeq()

  flowMap()
  blockMap()

  directives()
  reserves()
  aliases()

  unicodeSurrogates()

  examples()

  yamlHomepage()

  println("Done.")
}

test()
