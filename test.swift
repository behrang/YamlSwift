import Yaml

typealias Spec = [String: [String: ()->()]]

let spec: Spec = [
  "YamlValue.load": [

    "should return YamlNull for ``": {
      assert(Yaml.load("") == Yaml.YamlNull)
    },

    "should return YamlNull for `null` or `Null` or `NULL` or `~`": {
      assert(Yaml.load("null") == Yaml.YamlNull)
      assert(Yaml.load("Null") == Yaml.YamlNull)
      assert(Yaml.load("NULL") == Yaml.YamlNull)
      assert(Yaml.load("~") == Yaml.YamlNull)
    },

    "should NOT return YamlNull for `NuLL`": {
      assert(Yaml.load("NuLL") == nil)
    }
  ]
]

let indent = "    "
let checkmark = UnicodeScalar(0x2713)

for (key, value) in spec {
  println(key)
  for (key, value) in value {
    print("\(indent)   \(key)")
    value()
    println("\r\(indent) \(checkmark) \(key)")
  }
}
