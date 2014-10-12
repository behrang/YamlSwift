import Yaml

func null () {
  assert(Yaml.load("# comment line") == .Null)
  assert(Yaml.load("") == .Null)
  assert(Yaml.load("null") == .Null)
  assert(Yaml.load("Null") == .Null)
  assert(Yaml.load("NULL") == .Null)
  assert(Yaml.load("~") == .Null)
  assert(Yaml.load("NuLL") != .Null)
  assert(Yaml.load("null#") != .Null)
  assert(Yaml.load("null#string") != .Null)
  assert(Yaml.load("null #comment") == .Null)
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

  assert(Yaml.load("2.0") == 2)
  assert(Yaml.load("2.5") != 2)
  assert(Yaml.load("2.5").int == nil)
}

func float () {
  assert(Yaml.load(".inf") == .Float(Float.infinity))
  assert(Yaml.load(".Inf").float == Float.infinity)
  assert(Yaml.load(".INF") == Float.infinity)
  assert(Yaml.load(".iNf") != Float.infinity)
  assert(Yaml.load(".inf#") != Float.infinity)
  assert(Yaml.load(".inf# string") != Float.infinity)
  assert(Yaml.load(".inf # comment") == Float.infinity)
  assert(Yaml.load(".inf .inf") != Float.infinity)
  assert(Yaml.load("+.inf # comment") == Float.infinity)

  assert(Yaml.load("-.inf") == .Float(-Float.infinity))
  assert(Yaml.load("-.Inf").float == -Float.infinity)
  assert(Yaml.load("-.INF") == -Float.infinity)
  assert(Yaml.load("-.iNf") != -Float.infinity)
  assert(Yaml.load("-.inf#") != -Float.infinity)
  assert(Yaml.load("-.inf# string") != -Float.infinity)
  assert(Yaml.load("-.inf # comment") == -Float.infinity)
  assert(Yaml.load("-.inf -.inf") != -Float.infinity)

  assert(Yaml.load(".nan") == .Float(Float.NaN))
  assert(Yaml.load(".NaN") == .Float(Float.NaN))
  assert(Yaml.load(".NAN") == .Float(Float.NaN))
  assert(Yaml.load(".Nan") != .Float(Float.NaN))
  assert(Yaml.load(".nan#") != .Float(Float.NaN))
  assert(Yaml.load(".nan# string") != .Float(Float.NaN))
  assert(Yaml.load(".nan # comment") == .Float(Float.NaN))
  assert(Yaml.load(".nan .nan") != .Float(Float.NaN))

  assert(Yaml.load("0.") == .Float(0))
  assert(Yaml.load(".0").float == 0)
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
}

func string () {
  assert(Yaml.load("Behrang") == .String("Behrang"))
  assert(Yaml.load("Behrang Noruzi Niya").string == "Behrang Noruzi Niya")
}

func flowSeq () {
  assert(Yaml.load("[]") == .Seq([]))
  assert(Yaml.load("[]").count == 0)
  assert(Yaml.load("[ true]") == .Seq([.Bool(true)]))
  assert(Yaml.load("[ true]")[0] == true)
  assert(Yaml.load("[true, true  ,false,  false  ,  false]") ==
      .Seq([.Bool(true), .Bool(true), .Bool(false), .Bool(false), .Bool(false)]))
  assert(Yaml.load("[~, null, TRUE, False, .INF, -.inf, .NaN, 0, 123, -456, 0o74, 0xFf, 1.23, -4.5]") ==
      .Seq([.Null, .Null, .Bool(true), .Bool(false), .Float(Float.infinity), .Float(-Float.infinity),
          .Float(Float.NaN), .Int(0), .Int(123), .Int(-456), .Int(60), .Int(255), .Float(1.23),
          .Float(-4.5)]))
}

func blockSeq () {
  assert(Yaml.load("- 1\n- 2") == .Seq([.Int(1), .Int(2)]))
  assert(Yaml.load("- 1\n- 2")[1] == 2)
  assert(Yaml.load("- x: 1") == .Seq([.Map([.String("x"): .Int(1)])]))
  assert(Yaml.load("- x: 1\n  y: 2")[0] == .Map([.String("x"): .Int(1), .String("y"): .Int(2)]))
  assert(Yaml.load("- 1\n    \n- x: 1\n  y: 2") ==
      .Seq([.Int(1), .Map([.String("x"): .Int(1), .String("y"): .Int(2)])]))
}

func flowMap () {
  assert(Yaml.load("{}") == .Map([:]))
  assert(Yaml.load("{x: 1}") == .Map([.String("x"): .Int(1)]))
  assert(Yaml.load("{x: 1}")["x"] == 1)
  assert(Yaml.load("{x:1}").map == nil)
  assert(Yaml.load("{\"x\":1}")["x"] == 1)
  assert(Yaml.load("{\"x\":1, 'y': true}")["y"] == true)
  assert(Yaml.load("{\"x\":1, 'y': true, z: null}")["z"] == .Null)
  assert(Yaml.load("{first name: \"Behrang\", last name: 'Noruzi Niya'}") ==
      .Map([.String("first name"): .String("Behrang"), .String("last name"): .String("Noruzi Niya")]))
  assert(Yaml.load("{fn: Behrang, ln: Noruzi Niya}")["ln"].string == "Noruzi Niya")
  assert(Yaml.load("{fn: Behrang\n ,\nln: Noruzi Niya}")["ln"].string == "Noruzi Niya")
}

func blockMap () {
  assert(Yaml.load("x: 1\ny: 2") == .Map([.String("x"): .Int(1), .String("y"): .Int(2)]))
  assert(Yaml.load("x: 1\n? y\n: 2") == .Map([.String("x"): .Int(1), .String("y"): .Int(2)]))
  assert(Yaml.load("x: 1\n?  y\n:\n2") == .Map([.String("x"): .Int(1), .String("y"): .Int(2)]))
  assert(Yaml.load("x: 1\n?  y") == .Map([.String("x"): .Int(1), .String("y"): .Null]))
  assert(Yaml.load("?  y") == .Map([.String("y"): .Null]))
  assert(Yaml.load(" \n  \n \n  \n\nx: 1  \n   \ny: 2\n   \n  \n ")["y"] == 2)
  assert(Yaml.load("x:\n a: 1 # comment \n b: 2\ny: \n  c: 3\n  ")["y"]["c"] == 3)
  assert(Yaml.load("# comment \n\n  # x\n  # y \n  \n  x: 1  \n  y: 2") ==
      .Map([.String("x"): .Int(1), .String("y"): .Int(2)]))
}

func example0 () {
  let value = Yaml.load(
    "- just: write some\n" +
    "- yaml: \n" +
    "  - [here, and]\n" +
    "  - {it: updates, in: real-time}\n"
  )
  assert(value.count == 2)
  assert(value[0]["just"].string == "write some")
  assert(value[1]["yaml"][0][1].string == "and")
  assert(value[1]["yaml"][1]["in"].string == "real-time")
}

func example1 () {
  let value = Yaml.load(
    "- Mark McGwire\n" +
    "- Sammy Sosa\n" +
    "- Ken Griffey\n"
  )
  assert(value.count == 3)
  assert(value[1].string == "Sammy Sosa")
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
  assert(value["national"][2].string == "Atlanta Braves")
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
  assert(value[0][1].string == "Sammy Sosa")
  assert(value[1].count == 2)
  assert(value[1][1].string == "St Louis Cardinals")
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
  assert(value[0]["player"].string == "Sammy Sosa")
  assert(value[0]["time"] == 72200)
  assert(value[1]["player"].string == "Sammy Sosa")
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
  assert(value["hr"][1].string == "Sammy Sosa")
  assert(value["rbi"][1].string == "Ken Griffey")
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
  assert(value["hr"][1].string == "Sammy Sosa")
  assert(value["rbi"].count == 2)
  assert(value["rbi"][0].string == "Sammy Sosa")
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
  assert(value.count == 2)
  assert(value.map!.keys.first!.count == 2)
  assert(value.map!.keys.last!.count == 2)
  assert(value.map!.keys.last != value.map!.keys.first)
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
}

func test () {
  null()
  bool()
  int()
  float()
  string()

  flowSeq()
  blockSeq()

  flowMap()
  blockMap()

  examples()

  println("Done.")
}

test()
