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
  assert(Yaml.load("TRUE").bool == true)
  assert(Yaml.load("trUE").bool != true)
  assert(Yaml.load("true#").bool != true)
  assert(Yaml.load("true#string").bool != true)
  assert(Yaml.load("true #comment").bool == true)
  assert(Yaml.load("true  #").bool == true)
  assert(Yaml.load("true  ").bool == true)
  assert(Yaml.load("true\n").bool == true)
  assert(Yaml.load("true \n").bool == true)

  assert(Yaml.load("false") == .Bool(false))
  assert(Yaml.load("False").bool == false)
  assert(Yaml.load("FALSE").bool == false)
  assert(Yaml.load("faLSE").bool != false)
  assert(Yaml.load("false#").bool != false)
  assert(Yaml.load("false#string").bool != false)
  assert(Yaml.load("false #comment").bool == false)
  assert(Yaml.load("false  #").bool == false)
  assert(Yaml.load("false  ").bool == false)
  assert(Yaml.load("false\n").bool == false)
  assert(Yaml.load("false \n").bool == false)
}

func int () {
  assert(Yaml.load("0") == .Int(0))
  assert(Yaml.load("+0").int == 0)
  assert(Yaml.load("-0").int == 0)
  assert(Yaml.load("2").int == 2)
  assert(Yaml.load("+2").int == 2)
  assert(Yaml.load("-2").int == -2)
  assert(Yaml.load("00123").int == 123)
  assert(Yaml.load("+00123").int == 123)
  assert(Yaml.load("-00123").int == -123)
  assert(Yaml.load("0o10").int == 8)
  assert(Yaml.load("0o010").int == 8)
  assert(Yaml.load("0o0010").int == 8)
  assert(Yaml.load("0x10").int == 16)
  assert(Yaml.load("0x1a").int == 26)
  assert(Yaml.load("0x01a").int == 26)
  assert(Yaml.load("0x001a").int == 26)

  assert(Yaml.load("2.0").int == 2)
  assert(Yaml.load("2.5").int == nil)
}

func float () {
  assert(Yaml.load(".inf") == .Float(Float.infinity))
  assert(Yaml.load(".Inf").float == Float.infinity)
  assert(Yaml.load(".INF").float == Float.infinity)
  assert(Yaml.load(".iNf").float != Float.infinity)
  assert(Yaml.load(".inf#").float != Float.infinity)
  assert(Yaml.load(".inf# string").float != Float.infinity)
  assert(Yaml.load(".inf # comment").float == Float.infinity)
  assert(Yaml.load(".inf .inf").float != Float.infinity)
  assert(Yaml.load("+.inf # comment").float == Float.infinity)

  assert(Yaml.load("-.inf") == .Float(-Float.infinity))
  assert(Yaml.load("-.Inf").float == -Float.infinity)
  assert(Yaml.load("-.INF").float == -Float.infinity)
  assert(Yaml.load("-.iNf").float != -Float.infinity)
  assert(Yaml.load("-.inf#").float != -Float.infinity)
  assert(Yaml.load("-.inf# string").float != -Float.infinity)
  assert(Yaml.load("-.inf # comment").float == -Float.infinity)
  assert(Yaml.load("-.inf -.inf").float != -Float.infinity)

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
  assert(Yaml.load("+0.").float == 0)
  assert(Yaml.load("+.0").float == 0)
  assert(Yaml.load("+.").float != 0)
  assert(Yaml.load("-0.").float == 0)
  assert(Yaml.load("-.0").float == 0)
  assert(Yaml.load("-.").float != 0)
  assert(Yaml.load("2.").float == 2)
  assert(Yaml.load(".2").float == 0.2)
  assert(Yaml.load("+2.").float == 2)
  assert(Yaml.load("+.2").float == 0.2)
  assert(Yaml.load("-2.").float == -2)
  assert(Yaml.load("-.2").float == -0.2)
  assert(Yaml.load("1.23015e+3").float == 1.23015e+3)
  assert(Yaml.load("12.3015e+02").float == 12.3015e+02)
  assert(Yaml.load("1230.15").float == 1230.15)
  assert(Yaml.load("+1.23015e+3").float == 1.23015e+3)
  assert(Yaml.load("+12.3015e+02").float == 12.3015e+02)
  assert(Yaml.load("+1230.15").float == 1230.15)
  assert(Yaml.load("-1.23015e+3").float == -1.23015e+3)
  assert(Yaml.load("-12.3015e+02").float == -12.3015e+02)
  assert(Yaml.load("-1230.15").float == -1230.15)
  assert(Yaml.load("-01230.15").float == -1230.15)
  assert(Yaml.load("-12.3015e02").float == -12.3015e+02)
}

func string () {
  assert(Yaml.load("Behrang") == .String("Behrang"))
  assert(Yaml.load("Behrang Noruzi Niya").string == "Behrang Noruzi Niya")
}

func flowSeq () {
  assert(Yaml.load("[]") == .Seq([]))
  assert(Yaml.load("[]").seq!.count == 0)
  assert(Yaml.load("[ true]") == .Seq([.Bool(true)]))
  assert(Yaml.load("[ true]").seq![0].bool == true)
  assert(Yaml.load("[true, true  ,false,  false  ,  false]") ==
      .Seq([.Bool(true), .Bool(true), .Bool(false), .Bool(false), .Bool(false)]))
  assert(Yaml.load("[~, null, TRUE, False, .INF, -.inf, .NaN, 0, 123, -456, 0o74, 0xFf, 1.23, -4.5]") ==
      .Seq([.Null, .Null, .Bool(true), .Bool(false), .Float(Float.infinity), .Float(-Float.infinity),
          .Float(Float.NaN), .Int(0), .Int(123), .Int(-456), .Int(60), .Int(255), .Float(1.23),
          .Float(-4.5)]))
}

func blockSeq () {
  assert(Yaml.load("- 1\n- 2") == .Seq([.Int(1), .Int(2)]))
  assert(Yaml.load("- 1\n- 2").seq![1].int == 2)
  assert(Yaml.load("- x: 1") == .Seq([.Map(["x": .Int(1)])]))
  assert(Yaml.load("- x: 1\n  y: 2").seq![0] == .Map(["x": .Int(1), "y": .Int(2)]))
  assert(Yaml.load("- 1\n    \n- x: 1\n  y: 2") ==
      .Seq([.Int(1), .Map(["x": .Int(1), "y": .Int(2)])]))
}

func flowMap () {
  assert(Yaml.load("{}") == .Map([:]))
  assert(Yaml.load("{x: 1}") == .Map(["x": .Int(1)]))
  assert(Yaml.load("{x: 1}").map!["x"]!.int == 1)
  assert(Yaml.load("{x:1}").map == nil)
  assert(Yaml.load("{\"x\":1}").map!["x"]!.int == 1)
  assert(Yaml.load("{\"x\":1, 'y': true}").map!["y"]!.bool == true)
  assert(Yaml.load("{\"x\":1, 'y': true, z: null}").map!["z"]! == .Null)
  assert(Yaml.load("{first name: \"Behrang\", last name: 'Noruzi Niya'}") ==
      .Map(["first name": .String("Behrang"), "last name": .String("Noruzi Niya")]))
  assert(Yaml.load("{fn: Behrang, ln: Noruzi Niya}").map!["ln"]!.string == "Noruzi Niya")
  assert(Yaml.load("{fn: Behrang\n ,\nln: Noruzi Niya}").map!["ln"]!.string == "Noruzi Niya")
}

func blockMap () {
  assert(Yaml.load("x: 1\ny: 2") == .Map(["x": .Int(1), "y": .Int(2)]))
  assert(Yaml.load(" \n  \n \n  \n\nx: 1  \n   \ny: 2\n   \n  \n ").map!["y"]!.int == 2)
  assert(Yaml.load("x:\n a: 1 # comment \n b: 2\ny: \n  c: 3\n  ").map!["y"]!.map!["c"]!.int == 3)
  assert(Yaml.load("# comment \n\n  # x\n  # y \n  \n  x: 1  \n  y: 2") ==
      .Map(["x": .Int(1), "y": .Int(2)]))
}

func example1 () {
  let value = Yaml.load(
    "- just: write some\n" +
    "- yaml: \n" +
    "  - [here, and]\n" +
    "  - {it: updates, in: real-time}\n"
  )
  assert(value.seq!.count == 2)
  assert(value.seq![0].map!["just"]!.string! == "write some")
  assert(value.seq![1].map!["yaml"]!.seq![0].seq![1].string! == "and")
  assert(value.seq![1].map!["yaml"]!.seq![1].map!["in"]!.string! == "real-time")
}

func examples () {
  example1()
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
