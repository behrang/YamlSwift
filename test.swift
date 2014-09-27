import Yaml

typealias Spec = [String: [String: ()->()]]

let spec: Spec = [
  "YamlValue.load": [
    "should return YamlNull for empty input": {
      assert(Yaml.load("") == Yaml.YamlNull)
    }
  ]
]

let indent = "    "
let checkmark = UnicodeScalar(0x2713)

for (key, value) in spec {
  println(key)
  for (key, value) in value {
    print("\(indent) \(key) ")
    value()
    println(checkmark)
  }
}
