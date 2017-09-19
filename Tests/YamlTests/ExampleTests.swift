import Yaml
import XCTest

class ExampleTests: XCTestCase {
  
  func testExample0 () {
    var value = try! Yaml.load(
      "- just: write some\n" +
        "- yaml: \n" +
        "  - [here, and]\n" +
      "  - {it: updates, in: real-time}\n"
      )
    XCTAssert(value.count == 2)
    XCTAssert(value[0]["just"] == "write some")
    XCTAssert(value[1]["yaml"][0][1] == "and")
    XCTAssert(value[1]["yaml"][1]["in"] == "real-time")
    
    value[0]["just"] = .string("replaced string")
    XCTAssert(value[0]["just"] == "replaced string")
    value[0]["another"] = .int(2)
    XCTAssert(value[0]["another"] == 2)
    value[0]["new"]["key"][10]["key"] = .string("Ten")
    XCTAssert(value[0]["new"]["key"][10]["key"] == "Ten")
    value[0]["new"]["key"][5]["key"] = .string("Five")
    XCTAssert(value[0]["new"]["key"][5]["key"] == "Five")
    value[0]["new"]["key"][15]["key"] = .string("Fifteen")
    XCTAssert(value[0]["new"]["key"][15]["key"] == "Fifteen")
    value[2] = .double(2)
    XCTAssert(value[2] == 2)
    value = nil
    XCTAssert(value == nil)
  }
  
  func testExample1 () {
    let value = try! Yaml.load(
      "- Mark McGwire\n" +
        "- Sammy Sosa\n" +
      "- Ken Griffey\n"
      )
    XCTAssert(value.count == 3)
    XCTAssert(value[1] == "Sammy Sosa")
  }
  
  func testExample2 () {
    let value = try! Yaml.load(
      "hr:  65    # Home runs\n" +
        "avg: 0.278 # Batting average\n" +
      "rbi: 147   # Runs Batted In\n"
      )
    XCTAssert(value.count == 3)
    XCTAssert(value["avg"] == 0.278)
  }
  
  func testExample3 () {
    let value = try! Yaml.load(
      "american:\n" +
        "  - Boston Red Sox\n" +
        "  - Detroit Tigers\n" +
        "  - New York Yankees\n" +
        "national:\n" +
        "  - New York Mets\n" +
        "  - Chicago Cubs\n" +
      "  - Atlanta Braves\n"
      )
    XCTAssert(value.count == 2)
    XCTAssert(value["national"].count == 3)
    XCTAssert(value["national"][2] == "Atlanta Braves")
  }
  
  func testExample4 () {
    let value = try! Yaml.load(
      "-\n" +
        "  name: Mark McGwire\n" +
        "  hr:   65\n" +
        "  avg:  0.278\n" +
        "-\n" +
        "  name: Sammy Sosa\n" +
        "  hr:   63\n" +
      "  avg:  0.288\n"
      )
    XCTAssert(value.count == 2)
    XCTAssertEqual(value[1]["avg"].double!, 0.288, accuracy: 0.00001)
  }
  
  func testExample5 () {
    let value = try! Yaml.load(
      "- [name        , hr, avg  ]\n" +
        "- [Mark McGwire, 65, 0.278]\n" +
      "- [Sammy Sosa  , 63, 0.288]\n"
      )
    XCTAssert(value.count == 3)
    XCTAssert(value[2].count == 3)
    XCTAssertEqual(value[2][2].double!, 0.288, accuracy: 0.00001)
  }
  
  func testExample6 () {
    let value = try! Yaml.load(
      "Mark McGwire: {hr: 65, avg: 0.278}\n" +
        "Sammy Sosa: {\n" +
        "    hr: 63,\n" +
        "    avg: 0.288\n" +
      "  }\n"
      )
    XCTAssert(value["Mark McGwire"]["hr"] == 65)
    XCTAssert(value["Sammy Sosa"]["hr"] == 63)
  }
  
  func testExample7 () {
    let value = try! Yaml.loadMultiple(
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
    XCTAssert(value.count == 2)
    XCTAssert(value[0].count == 3)
    XCTAssert(value[0][1] == "Sammy Sosa")
    XCTAssert(value[1].count == 2)
    XCTAssert(value[1][1] == "St Louis Cardinals")
  }
  
  func testExample8 () {
    let value = try! Yaml.loadMultiple(
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
    XCTAssert(value.count == 2)
    XCTAssert(value[0]["player"] == "Sammy Sosa")
    XCTAssert(value[0]["time"] == 72200)
    XCTAssert(value[1]["player"] == "Sammy Sosa")
    XCTAssert(value[1]["time"] == 72227)
  }
  
  func testExample9 () {
    let value = try! Yaml.load(
      "---\n" +
        "hr: # 1998 hr ranking\n" +
        "  - Mark McGwire\n" +
        "  - Sammy Sosa\n" +
        "rbi:\n" +
        "  # 1998 rbi ranking\n" +
        "  - Sammy Sosa\n" +
      "  - Ken Griffey\n"
      )
    XCTAssert(value["hr"][1] == "Sammy Sosa")
    XCTAssert(value["rbi"][1] == "Ken Griffey")
  }
  
  func testExample10 () {
    let value = try! Yaml.load(
      "---\n" +
        "hr:\n" +
        "  - Mark McGwire\n" +
        "  # Following node labeled SS\n" +
        "  - &SS Sammy Sosa\n" +
        "rbi:\n" +
        "  - *SS # Subsequent occurrence\n" +
      "  - Ken Griffey\n"
      )
    XCTAssert(value["hr"].count == 2)
    XCTAssert(value["hr"][1] == "Sammy Sosa")
    XCTAssert(value["rbi"].count == 2)
    XCTAssert(value["rbi"][0] == "Sammy Sosa")
  }
  
  func testExample11 () {
    let value = try! Yaml.load(
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
    let key1 = try! Yaml.load("- Detroit Tigers\n- Chicago cubs\n")
    let key2 = try! Yaml.load("- New York Yankees\n- Atlanta Braves")
    XCTAssert(value.count == 2)
    XCTAssert(value[key1].count == 1)
    XCTAssert(value[key2].count == 3)
    XCTAssert(value[key2][2] == "2001-08-14")
  }
  
  func testExample12 () {
    let value = try! Yaml.load(
      "---\n" +
        "# Products purchased\n" +
        "- item    : Super Hoop\n" +
        "  quantity: 1\n" +
        "- item    : Basketball\n" +
        "  quantity: 4\n" +
        "- item    : Big Shoes\n" +
      "  quantity: 1\n"
      )
    XCTAssert(value.count == 3)
    XCTAssert(value[1].count == 2)
    XCTAssert(value[1]["item"] == "Basketball")
    XCTAssert(value[1]["quantity"] == 4)
    let key = try! Yaml.load("quantity")
    XCTAssert(value[2][key] == 1)
  }
  
  func testExample13 () {
    let value = try! Yaml.load(
      "# ASCII Art\n" +
        "--- |\n" +
        "  \\//||\\/||\n" +
      "  // ||  ||__\n"
      )
    XCTAssert(value == "\\//||\\/||\n// ||  ||__\n")
  }
  
  func testExample14 () {
    let value = try! Yaml.load(
      "--- >\n" +
        "  Mark McGwire's\n" +
        "  year was crippled\n" +
      "  by a knee injury.\n"
      )
    XCTAssert(value == "Mark McGwire's year was crippled by a knee injury.\n")
  }
  
  func testExample15 () {
    let value = try! Yaml.load(
      ">\n" +
        " Sammy Sosa completed another\n" +
        " fine season with great stats.\n" +
        "\n" +
        "   63 Home Runs\n" +
        "   0.288 Batting Average\n" +
        "\n" +
      " What a year!\n"
      )
    XCTAssert(value ==
      .string("Sammy Sosa completed another fine season with great stats.\n\n" +
        "  63 Home Runs\n  0.288 Batting Average\n\nWhat a year!\n"))
  }
  
  func testExample16 () {
    let value = try! Yaml.load(
      "name: Mark McGwire\n" +
        "accomplishment: >\n" +
        "  Mark set a major league\n" +
        "  home run record in 1998.\n" +
        "stats: |\n" +
        "  65 Home Runs\n" +
      "  0.278 Batting Average\n"
      )
    XCTAssert(value["accomplishment"] ==
      "Mark set a major league home run record in 1998.\n")
    XCTAssert(value["stats"] == "65 Home Runs\n0.278 Batting Average\n")
  }
  
  func testExample17 () {
    let value = try! Yaml.load(
      "unicode: \"Sosa did fine.\\u263A\"\n" +
        "control: \"\\b1998\\t1999\\t2000\\n\"\n" +
        "hex esc: \"\\x0d\\x0a is \\r\\n\"\n" +
        "\n" +
        "single: '\"Howdy!\" he cried.'\n" +
        "quoted: ' # Not a ''comment''.'\n" +
      "tie-fighter: '|\\-*-/|'\n"
      )
    // FIXME: Failing with Xcode8b6
    // XCTAssert(value["unicode"] == "Sosa did fine.\u{263A}")
    XCTAssert(value["control"] == "\u{8}1998\t1999\t2000\n")
    // FIXME: Failing with Xcode8b6
    // XCTAssert(value["hex esc"] == "\u{d}\u{a} is \r\n")
    XCTAssert(value["single"] == "\"Howdy!\" he cried.")
    XCTAssert(value["quoted"] == " # Not a 'comment'.")
    XCTAssert(value["tie-fighter"] == "|\\-*-/|")
  }
  
  func testExample18 () {
    let value = try! Yaml.load(
      "plain:\n" +
        "  This unquoted scalar\n" +
        "  spans many lines.\n" +
        "\n" +
        "quoted: \"So does this\n" +
      "  quoted scalar.\\n\"\n"
      )
    XCTAssert(value.count == 2)
    XCTAssert(value["plain"] == "This unquoted scalar spans many lines.")
    XCTAssert(value["quoted"] == "So does this quoted scalar.\n")
  }
  
  func testExample19 () {
    let value = try! Yaml.load(
      "canonical: 12345\n" +
        "decimal: +12345\n" +
        "octal: 0o14\n" +
      "hexadecimal: 0xC\n"
      )
    XCTAssert(value.count == 4)
    XCTAssert(value["canonical"] == 12345)
    XCTAssert(value["decimal"] == 12345)
    XCTAssert(value["octal"] == 12)
    XCTAssert(value["hexadecimal"] == 12)
  }
  
  func testExample20 () {
    let value = try! Yaml.load(
      "canonical: 1.23015e+3\n" +
        "exponential: 12.3015e+02\n" +
        "fixed: 1230.15\n" +
        "negative infinity: -.inf\n" +
      "not a number: .NaN\n"
      )
    XCTAssert(value.count == 5)
    /* Disabled for Linux */
#if !os(Linux)
    XCTAssert(value["canonical"] == 1.23015e+3)
    XCTAssert(value["exponential"] == 1.23015e+3)
    XCTAssert(value["fixed"] == 1.23015e+3)
#endif
    XCTAssert(value["negative infinity"] == .double(-Double.infinity))
    XCTAssert(value["not a number"].double?.isNaN == true)
  }
  
  func testExample21 () {
    let value = try! Yaml.load(
      "null:\n" +
        "booleans: [ true, false ]\n" +
      "string: '012345'\n"
      )
    XCTAssert(value.count == 3)
    XCTAssert(value["null"] == nil)
    XCTAssert(value["booleans"] == [true, false])
    XCTAssert(value["string"] == "012345")
  }
  
  func testExample22 () {
    let value = try! Yaml.load(
      "canonical: 2001-12-15T02:59:43.1Z\n" +
        "iso8601: 2001-12-14t21:59:43.10-05:00\n" +
        "spaced: 2001-12-14 21:59:43.10 -5\n" +
      "date: 2002-12-14\n"
      )
    XCTAssert(value.count == 4)
    XCTAssert(value["canonical"] == "2001-12-15T02:59:43.1Z")
    XCTAssert(value["iso8601"] == "2001-12-14t21:59:43.10-05:00")
    XCTAssert(value["spaced"] == "2001-12-14 21:59:43.10 -5")
    XCTAssert(value["date"] == "2002-12-14")
  }
  
  let exampleYaml =
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
  
  func testYamlHomepage () {
    let value = try! Yaml.load(exampleYaml)
    XCTAssert(value.count == 6)
    XCTAssert(value["YAML"] == "YAML Ain't Markup Language")
    XCTAssert(value["What It Is"] == .string("YAML is a human friendly data" +
      " serialization standard for all programming languages."))
    XCTAssert(value["YAML Resources"].count == 8)
    XCTAssert(value["YAML Resources"]["YAML 1.2 (3rd Edition)"] ==
      "http://yaml.org/spec/1.2/spec.html")
    XCTAssert(value["YAML Resources"]["YAML IRC Channel"] ==
      "#yaml on irc.freenode.net")
    XCTAssert(value["Projects"].count == 12)
    XCTAssert(value["Projects"]["C/C++ Libraries"][2] == "yaml-cpp")
    XCTAssert(value["Projects"]["Perl Modules"].count == 5)
    XCTAssert(value["Projects"]["Perl Modules"][0] == "YAML")
    XCTAssert(value["Projects"]["Perl Modules"][1] == "YAML::XS")
    XCTAssert(value["Related Projects"].count == 6)
    XCTAssert(value["News"].count == 2)
  }
  
  func testPerformanceExample() {
    self.measure() {
      _ = try! Yaml.load(self.exampleYaml)
    }
  }
  
}

#if os(Linux)

extension ExampleTests {
  static var allTests: [(String, (ExampleTests) -> () throws -> Void)] {
    return [
      ("testExample0", testExample0),
      ("testExample1", testExample1),
      ("testExample2", testExample2),
      ("testExample3", testExample3),
      ("testExample4", testExample4),
      ("testExample5", testExample5),
      ("testExample6", testExample6),
      ("testExample7", testExample7),
      ("testExample8", testExample8),
      ("testExample9", testExample9),
      ("testExample10", testExample10),
      ("testExample11", testExample11),
      ("testExample12", testExample12),
      ("testExample13", testExample13),
      ("testExample14", testExample14),
      ("testExample15", testExample15),
      ("testExample16", testExample16),
      ("testExample17", testExample17),
      ("testExample18", testExample18),
      ("testExample19", testExample19),
      ("testExample20", testExample20),
      ("testExample21", testExample21),
      ("testExample22", testExample22),
      ("testYamlHomepage", testYamlHomepage),
      ("testPerformanceExample", testPerformanceExample),
    ]
  }
}

#endif
