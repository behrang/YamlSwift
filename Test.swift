import Yaml

func null () {
  assert(Yaml.load("# comment line") == .Null)
  assert(Yaml.load("") == .Null)
  assert(Yaml.load("null") == .Null)
  assert(Yaml.load("Null") == nil)
  assert(Yaml.load("NULL") == nil)
  assert(Yaml.load("~") == nil)
  assert(Yaml.load("NuLL") != nil)
  assert(Yaml.load("null#") != nil)
  assert(Yaml.load("null#string") != nil)
  assert(Yaml.load("null #comment") == nil)

  let value: Yaml = nil
  assert(value == nil)
}

func bool () {
  assert(Yaml.load("true") == .Bool(true))
  assert(Yaml.load("True").bool == true)
  assert(Yaml.load("TRUE") == true)
  assert(Yaml.load("trUE") != true)
  assert(Yaml.load("true#") != true)
  assert(Yaml.load("true#string") != true)
  assert(Yaml.load("true #comment") == true)
  assert(Yaml.load("true  #") == true)
  assert(Yaml.load("true  ") == true)
  assert(Yaml.load("true\n") == true)
  assert(Yaml.load("true \n") == true)
  assert(true == Yaml.load("\ntrue \n"))

  assert(Yaml.load("false") == .Bool(false))
  assert(Yaml.load("False").bool == false)
  assert(Yaml.load("FALSE") == false)
  assert(Yaml.load("faLSE") != false)
  assert(Yaml.load("false#") != false)
  assert(Yaml.load("false#string") != false)
  assert(Yaml.load("false #comment") == false)
  assert(Yaml.load("false  #") == false)
  assert(Yaml.load("false  ") == false)
  assert(Yaml.load("false\n") == false)
  assert(Yaml.load("false \n") == false)
  assert(false == Yaml.load("\nfalse \n"))

  let value: Yaml = true
  assert(value == true)
  assert(value.bool == true)
}

func int () {
  assert(Yaml.load("0") == .Int(0))
  assert(Yaml.load("+0").int == 0)
  assert(Yaml.load("-0") == 0)
  assert(Yaml.load("2") == 2)
  assert(Yaml.load("+2") == 2)
  assert(Yaml.load("-2") == -2)
  assert(Yaml.load("00123") == 123)
  assert(Yaml.load("+00123") == 123)
  assert(Yaml.load("-00123") == -123)
  assert(Yaml.load("0o10") == 8)
  assert(Yaml.load("0o010") == 8)
  assert(Yaml.load("0o0010") == 8)
  assert(Yaml.load("0x10") == 16)
  assert(Yaml.load("0x1a") == 26)
  assert(Yaml.load("0x01a") == 26)
  assert(Yaml.load("0x001a") == 26)
  assert(Yaml.load("10:10") == 610)
  assert(Yaml.load("10:10:10") == 36610)

  assert(Yaml.load("2") == 2)
  assert(Yaml.load("2.0") == 2)
  assert(Yaml.load("2.5") != 2)
  assert(Yaml.load("2.5").int == nil)

  let value1: Yaml = 2
  assert(value1 == 2)
  assert(value1.int == 2)
  let value2: Yaml = -2
  assert(value2 == -2)
  assert(-value2 == 2)
  assert(-value2 == value1)
}

func double () {
  assert(Yaml.load(".inf") == .Double(Double.infinity))
  assert(Yaml.load(".Inf").double == Double.infinity)
  assert(Yaml.load(".INF").double == Double.infinity)
  assert(Yaml.load(".iNf").double != Double.infinity)
  assert(Yaml.load(".inf#").double != Double.infinity)
  assert(Yaml.load(".inf# string").double != Double.infinity)
  assert(Yaml.load(".inf # comment").double == Double.infinity)
  assert(Yaml.load(".inf .inf").double != Double.infinity)
  assert(Yaml.load("+.inf # comment").double == Double.infinity)

  assert(Yaml.load("-.inf") == .Double(-Double.infinity))
  assert(Yaml.load("-.Inf").double == -Double.infinity)
  assert(Yaml.load("-.INF").double == -Double.infinity)
  assert(Yaml.load("-.iNf").double != -Double.infinity)
  assert(Yaml.load("-.inf#").double != -Double.infinity)
  assert(Yaml.load("-.inf# string").double != -Double.infinity)
  assert(Yaml.load("-.inf # comment").double == -Double.infinity)
  assert(Yaml.load("-.inf -.inf").double != -Double.infinity)

  assert(Yaml.load(".nan") != .Double(Double.NaN))
  assert(Yaml.load(".nan").double!.isNaN)
  assert(Yaml.load(".NaN").double!.isNaN)
  assert(Yaml.load(".NAN").double!.isNaN)
  assert(Yaml.load(".Nan").double == nil)
  assert(Yaml.load(".nan#").double == nil)
  assert(Yaml.load(".nan# string").double == nil)
  assert(Yaml.load(".nan # comment").double!.isNaN)
  assert(Yaml.load(".nan .nan").double == nil)

  assert(Yaml.load("0.") == .Double(0))
  assert(Yaml.load(".0").double == 0)
  assert(Yaml.load("+0.") == 0)
  assert(Yaml.load("+.0") == 0)
  assert(Yaml.load("+.") != 0)
  assert(Yaml.load("-0.") == 0)
  assert(Yaml.load("-.0") == 0)
  assert(Yaml.load("-.") != 0)
  assert(Yaml.load("2.") == 2)
  assert(Yaml.load(".2") == 0.2)
  assert(Yaml.load("+2.") == 2)
  assert(Yaml.load("+.2") == 0.2)
  assert(Yaml.load("-2.") == -2)
  assert(Yaml.load("-.2") == -0.2)
  assert(Yaml.load("1.23015e+3") == 1.23015e+3)
  assert(Yaml.load("12.3015e+02") == 12.3015e+02)
  assert(Yaml.load("1230.15") == 1230.15)
  assert(Yaml.load("+1.23015e+3") == 1.23015e+3)
  assert(Yaml.load("+12.3015e+02") == 12.3015e+02)
  assert(Yaml.load("+1230.15") == 1230.15)
  assert(Yaml.load("-1.23015e+3") == -1.23015e+3)
  assert(Yaml.load("-12.3015e+02") == -12.3015e+02)
  assert(Yaml.load("-1230.15") == -1230.15)
  assert(Yaml.load("-01230.15") == -1230.15)
  assert(Yaml.load("-12.3015e02") == -12.3015e+02)

  assert(Yaml.load("2") == 2.0)
  assert(Yaml.load("2.0") == 2.0)
  assert(Yaml.load("2.5") == 2.5)
  assert(Yaml.load("2.5").int == nil)

  let value1: Yaml = 0.2
  assert(value1 == 0.2)
  assert(value1.double == 0.2)
  let value2: Yaml = -0.2
  assert(value2 == -0.2)
  assert(-value2 == 0.2)
  assert(-value2 == value1)
}

func string () {
  assert(Yaml.load("Behrang") == .String("Behrang"))
  assert(Yaml.load("\"Behrang\"") == .String("Behrang"))
  assert(Yaml.load("\"B\\\"ehran\\\"g\"") == .String("B\"ehran\"g"))
  assert(Yaml.load("Behrang Noruzi Niya").string == "Behrang Noruzi Niya")
  assert(Yaml.load("Radin Noruzi Niya") == "Radin Noruzi Niya")
  assert(Yaml.load("|") == "")
  assert(Yaml.load("| ") == "")
  assert(Yaml.load("|  # comment") == "")
  assert(Yaml.load("|  # comment\n") == "")
  assert(Yaml.load("|\nRadin") != "Radin")
  assert(Yaml.load("|\n Radin") == "Radin")
  assert(Yaml.load("|  \n Radin") == "Radin")
  assert(Yaml.load("|  # comment\n Radin") == "Radin")
  assert(Yaml.load("|\n  Radin") == "Radin")
  assert(Yaml.load("|2\n  Radin") == "Radin")
  assert(Yaml.load("|1\n  Radin") == " Radin")
  assert(Yaml.load("|1\n\n  Radin") == "\n Radin")
  assert(Yaml.load("|\n\n  Radin") == "\nRadin")
  assert(Yaml.load("|3\n\n  Radin") != "\nRadin")
  assert(Yaml.load("|3\n    \n   Radin") != " \nRadin")
  assert(Yaml.load("|3\n   \n   Radin") == "\nRadin")
  assert(Yaml.load("|\n  \n\n \n  Radin\n\n \n\n  Noruzi Niya") == "\n\n\nRadin\n\n\n\nNoruzi Niya")
  assert(Yaml.load("|\n  \n\n \n  Radin\n\n \n\n  Noruzi Niya\n  #1") ==
      "\n\n\nRadin\n\n\n\nNoruzi Niya\n#1")
  assert(Yaml.load("|\n  \n\n \n  Radin\n\n \n\n  Noruzi Niya\n  #1\n # Comment") ==
      "\n\n\nRadin\n\n\n\nNoruzi Niya\n#1\n")
  assert(Yaml.load("|\n Radin\n") == "Radin\n")
  assert(Yaml.load("|\n Radin\n\n") == "Radin\n")
  assert(Yaml.load("|\n Radin\n \n ") == "Radin\n")
  assert(Yaml.load("|\n Radin\n  \n  ") == "Radin\n")
  assert(Yaml.load("|-\n Radin\n  \n  ") == "Radin")
  assert(Yaml.load("|+\n Radin\n") == "Radin\n")
  assert(Yaml.load("|+\n Radin\n\n") == "Radin\n\n")
  assert(Yaml.load("|+\n Radin\n \n ") == "Radin\n\n")
  assert(Yaml.load("|+\n Radin\n  \n  ") == "Radin\n \n ")
  assert(Yaml.load("|2+\n  Radin\n  \n  ") == "Radin\n\n")
  assert(Yaml.load("|+2\n  Radin\n  \n  ") == "Radin\n\n")
  assert(Yaml.load("|-2\n  Radin\n  \n  ") == "Radin")
  assert(Yaml.load("|2-\n  Radin\n  \n  ") == "Radin")
  assert(Yaml.load("|22\n  Radin\n  \n  ") != "Radin\n\n")
  assert(Yaml.load("|--\n  Radin\n  \n  ") != "Radin\n\n")
  assert(Yaml.load(">+\n  trimmed\n  \n \n\n  as\n  space\n\n   \n") == "trimmed\n\n\nas space\n\n \n")
  assert(Yaml.load(">-\n  trimmed\n  \n \n\n  as\n  space") == "trimmed\n\n\nas space")
  assert(Yaml.load(">\n  foo \n \n  \t bar\n\n  baz\n") == "foo \n\n\t bar\n\nbaz\n")

  assert(Yaml.load(">\n  \n Behrang").string == nil)
  assert(Yaml.load(">\n  \n  Behrang") == "\nBehrang")
  assert(Yaml.load(">\n\n folded\n line\n\n next\n line\n" +
      "   * bullet\n\n   * list\n   * lines\n\n last\n line\n\n# Comment") ==
      "\nfolded line\nnext line\n  * bullet\n\n  * list\n  * lines\n\nlast line\n")

  assert(Yaml.load("\"\n  foo \n \n  \t bar\n\n  baz\n\"") == " foo\nbar\nbaz ")
  assert(Yaml.load("\"folded \nto a space,\t\n \nto a line feed, or \t\\\n \\ \tnon-content\"") ==
      "folded to a space,\nto a line feed, or \t \tnon-content")
  assert(Yaml.load("\" 1st non-empty\n\n 2nd non-empty \n\t3rd non-empty \"") ==
      " 1st non-empty\n2nd non-empty 3rd non-empty ")

  assert(Yaml.load("'here''s to \"quotes\"'") == "here's to \"quotes\"")
  assert(Yaml.load("' 1st non-empty\n\n 2nd non-empty \n\t3rd non-empty '") ==
      " 1st non-empty\n2nd non-empty 3rd non-empty ")

  let value: Yaml = "Radin"
  assert(value == "Radin")
  assert(value.string == "Radin")
}

func flowSeq () {
  assert(Yaml.load("[]") == .Array([]))
  assert(Yaml.load("[]").count == 0)
  assert(Yaml.load("[ true ]") == [Yaml.Bool(true)])
  assert(Yaml.load("[ true ]") == .Array([true]))
  assert(Yaml.load("[ true ]") == [true])
  assert(Yaml.load("[ true ]")[0] == true)
  assert(Yaml.load("[true, false, true]") == [true, false, true])
  assert(Yaml.load("[Behrang, Radin]") == ["Behrang", "Radin"])
  assert(Yaml.load("[true, [false, true]]") == [true, [false, true]])
  assert(Yaml.load("[true, true  ,false,  false  ,  false]") == [true, true, false, false, false])
  assert(Yaml.load("[true, .NaN]") != [true, .Double(Double.NaN)])
  assert(Yaml.load("[~, null, TRUE, False, .INF, -.inf, 0, 123, -456, 0o74, 0xFf, 1.23, -4.5]") ==
      [nil, nil, true, false, .Double(Double.infinity), .Double(-Double.infinity),
          0, 123, -456, 60, 255, 1.23, -4.5])
}

func blockSeq () {
  assert(Yaml.load("- 1\n- 2") == [1, 2])
  assert(Yaml.load("- 1\n- 2")[1] == 2)
  assert(Yaml.load("- x: 1") == [["x": 1]])
  assert(Yaml.load("- x: 1\n  y: 2")[0] == ["x": 1, "y": 2])
  assert(Yaml.load("- 1\n    \n- x: 1\n  y: 2") == [1, ["x": 1, "y": 2]])
}

func flowMap () {
  assert(Yaml.load("{}") == [:])
  assert(Yaml.load("{x: 1}") == ["x": 1])
  assert(Yaml.load("{x: 1}")["x"] == 1)
  assert(Yaml.load("{x:1}").dictionary == nil)
  assert(Yaml.load("{\"x\":1}")["x"] == 1)
  assert(Yaml.load("{\"x\":1, 'y': true}")["y"] == true)
  assert(Yaml.load("{\"x\":1, 'y': true, z: null}")["z"] == nil)
  assert(Yaml.load("{first name: \"Behrang\", last name: 'Noruzi Niya'}") ==
      ["first name": "Behrang", "last name": "Noruzi Niya"])
  assert(Yaml.load("{fn: Behrang, ln: Noruzi Niya}")["ln"] == "Noruzi Niya")
  assert(Yaml.load("{fn: Behrang\n ,\nln: Noruzi Niya}")["ln"] == "Noruzi Niya")
}

func blockMap () {
  assert(Yaml.load("x: 1\ny: 2") == .Dictionary([.String("x"): .Int(1), .String("y"): .Int(2)]))
  assert(Yaml.load("x: 1\n? y\n: 2") == ["x": 1, "y": 2])
  assert(Yaml.load("x: 1\n?  y\n:\n2") == ["x": 1, "y": 2])
  assert(Yaml.load("x: 1\n?  y") == ["x": 1, "y": nil])
  assert(Yaml.load("?  y") == ["y": nil])
  assert(Yaml.load(" \n  \n \n  \n\nx: 1  \n   \ny: 2\n   \n  \n ")["y"] == 2)
  assert(Yaml.load("x:\n a: 1 # comment \n b: 2\ny: \n  c: 3\n  ")["y"]["c"] == 3)
  assert(Yaml.load("# comment \n\n  # x\n  # y \n  \n  x: 1  \n  y: 2") == ["x": 1, "y": 2])
}

func directives () {
  assert(Yaml.load("%YAML 1.2\n1") != 1)
  assert(Yaml.load("%YAML   1.2\n---1") == 1)
  assert(Yaml.load("%YAML   1.2  #\n---1") == 1)
  assert(Yaml.load("%YAML   1.2\n%YAML 1.2\n---1") != 1)
  assert(Yaml.load("%YAML 1.0\n---1") != 1)
  assert(Yaml.load("%YAML 1\n---1") != 1)
  assert(Yaml.load("%YAML 1.3\n---1") != 1)
  assert(Yaml.load("%YAML \n---1") != 1)
}

func example0 () {
  var value = Yaml.load(
    "- just: write some\n" +
    "- yaml: \n" +
    "  - [here, and]\n" +
    "  - {it: updates, in: real-time}\n"
  )
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
  )
  assert(value.count == 3)
  assert(value[1] == "Sammy Sosa")
}

func example2 () {
  let value = Yaml.load(
    "hr:  65    # Home runs\n" +
    "avg: 0.278 # Batting average\n" +
    "rbi: 147   # Runs Batted In\n"
  )
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
  )
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
  )
  assert(value.count == 2)
  assert(value[1]["avg"] == 0.288)
}

func example5 () {
  let value = Yaml.load(
    "- [name        , hr, avg  ]\n" +
    "- [Mark McGwire, 65, 0.278]\n" +
    "- [Sammy Sosa  , 63, 0.288]\n"
  )
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
  )
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
  )
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
  )
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
  )
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
  )
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
  )
  let key1 = Yaml.load("- Detroit Tigers\n- Chicago cubs\n")
  let key2 = Yaml.load("- New York Yankees\n- Atlanta Braves")
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
  )
  assert(value.count == 3)
  assert(value[1].count == 2)
  assert(value[1]["item"] == "Basketball")
  assert(value[1]["quantity"] == 4)
  let key = Yaml.load("quantity")
  assert(value[2][key] == 1)
}

func example13 () {
  let value = Yaml.load(
    "# ASCII Art\n" +
    "--- |\n" +
    "  \\//||\\/||\n" +
    "  // ||  ||__\n"
  )
  assert(value == "\\//||\\/||\n// ||  ||__\n")
}

func example14 () {
  let value = Yaml.load(
    "--- >\n" +
    "  Mark McGwire's\n" +
    "  year was crippled\n" +
    "  by a knee injury.\n"
  )
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
  )
  assert(value == .String("Sammy Sosa completed another fine season with great stats.\n\n" +
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
  )
  assert(value["accomplishment"] == "Mark set a major league home run record in 1998.\n")
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
  )
  assert(value["unicode"] == "Sosa did fine.\u{263A}")
  assert(value["control"] == "\u{8}1998\t1999\t2000\n")
  assert(value["hex esc"] == "\u{d}\u{a} is \r\n")
  assert(value["single"] == "\"Howdy!\" he cried.")
  assert(value["quoted"] == " # Not a 'comment'.")
  assert(value["tie-fighter"] == "|\\-*-/|")
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

  examples()

  println("Done.")
}

test()
