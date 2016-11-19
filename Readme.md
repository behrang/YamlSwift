# YamlSwift

Load [YAML](http://yaml.org) and [JSON](http://json.org) documents using [Swift](http://www.apple.com/swift/).

`YamlSwift` parses a string of YAML document(s) (or a JSON document, since YAML is mostly a superset of JSON) and returns a `Yaml` enum value representing that string. Version 4 is spec-compliant and supports Yaml 1.2. Currently circular references in Yaml documents are not supported.





## Install

Using swift package manager, add this dependency to your `Package.swift` file:
```swift
.Package(url: "git@github.com:behrang/YamlSwift.git", majorVersion: 4)
```





## API





### import

To use it, you should import it using the following statement:

```swift
import Yaml
```





### Yaml

A Yaml value can be any of these cases:

```swift
enum Yaml {
  case null
  case bool(Bool)
  case int(Int)
  case double(Double)
  case string(String)
  case array([Yaml])
  case dictionary([Yaml: Yaml])
}
```





### Yaml.load

```swift
Yaml.load (String, Schema = core_schema) throws -> [Yaml]
```

Takes a string of a YAML document and an optional schema and returns an array of `Yaml` enums.

```swift
let docs = try! Yaml.load("age: 33\nname: Behrang")
let doc = docs[0]
print(doc["age"])  // int(33)
print(doc["name"])  // string(Behrang)
print(doc["c"])  // null()
```

If the input document is invalid an error is thrown.

```swift
do {
  let _ = try Yaml.load("a\nb: 2")
}
catch {
  print(error) // (line 2, column 2): unexpected ":"
}
```

Since a Yaml stream can contain multiple documents (separated by `---` and `...` markers), `load` returns an array of `Yaml` documents.

`Schema` is optional and defines supported `tags` and `resolve` mechanism. `core_schema` is default and supports these tags: `!!map`, `!!seq`, `!!str`, `!!null`, `!!bool`, `!!int`, and `!!float`.





### Yaml#[Yaml] -> Yaml

```swift
value[Yaml] -> Yaml
value[Yaml] = Yaml
```

If used on a `Yaml.dictionary` value, it will return the value for the specified key. If a value for the specified key does not exist, or value is not a `Yaml.dictionary`, `Yaml.null` is returned. You can also set a value for a specific key. If the value is not a `Yaml.dictionary`, it will change to it after set.

Since `Yaml` is a literal convertible type, you can pass simple values to this method.

```swift
var person = try! Yaml.load("first name: Behrang\nlast name: Noruzi Niya")[0]
print(person["first name"])  // string(Behrang)
print(person["last name"])  // string(Noruzi Niya)
print(person["age"])  // null()
person["first name"] = "Radin"
person["age"] = 1
print(person["first name"])  // string(Radin)
print(person["last name"])  // string(Noruzi Niya)
print(person["age"])  // int(1)
```





### Yaml#[Int] -> Yaml

```swift
value[Int] -> Yaml
value[Int] = Yaml
```

If used on a `Yaml.array` value, it will return the value at the specified index. If the index is invalid or the value is not a `Yaml.array`, `Yaml.null` is returned. You can also set a value at a specific index. Enough elements will be added to the wrapped array to set the specified index. If the value is not a `Yaml.array`, it will change to it after set.

```swift
var family = try! Yaml.load("- Behrang\n- Maryam")[0]
print(family[0])  // string(Behrang)
print(family[1])  // string(Maryam)
print(family[2])  // null()
family[2] = "Radin"
print(family[2])  // string(Radin)
```





### Yaml#string

```swift
value.string -> String?
```

Returns an `Optional<String>` value. If the value is a `Yaml.string` value, the wrapped value is returned. Otherwise `nil` is returned.

```swift
let person = try! Yaml.load("first name: Behrang\nlast name: Noruzi Niya\nage: 33")[0]
print(person["first name"].string)  // Optional("Behrang")
print(person["last name"].string)  // Optional("Noruzi Niya")
print(person["age"].string)  // nil
```





### Yaml#bool

```swift
value.bool -> Bool?
```

Returns an `Optional<Bool>` value. If the value is a `Yaml.bool` value, the wrapped value is returned. Otherwise `nil` is returned.

```swift
let value = try! Yaml.load("animate: true\nshow tip: false\nusage: 25")[0]
print(value["animate"].bool)  // Optional(true)
print(value["show tip"].bool)  // Optional(false)
print(value["usage"].bool)  // nil
```





### Yaml#int

```swift
value.int -> Int?
```

Returns an `Optional<Int>` value. If the value is a `Yaml.int` value, the wrapped value is returned. Otherwise `nil` is returned.

```swift
let value = try! Yaml.load("a: 1\nb: 2.0\nc: 2.5")[0]
print(value["a"].int)  // Optional(1)
print(value["b"].int)  // Optional(2)
print(value["c"].int)  // nil
```





### Yaml#double

```swift
value.double -> Double?
```

Returns an `Optional<Double>` value. If the value is a `Yaml.double` value, the wrapped value is returned. Otherwise `nil` is returned.

```swift
let value = try! Yaml.load("a: 1\nb: 2.0\nc: 2.5\nd: true")[0]
print(value["a"].double)  // Optional(1.0)
print(value["b"].double)  // Optional(2.0)
print(value["c"].double)  // Optional(2.5)
print(value["d"].double)  // nil
```





### Yaml#array

```swift
value.array -> [Yaml]?
```

Returns an `Optional<Array<Yaml>>` value. If the value is a `Yaml.array` value, the wrapped value is returned. Otherwise `nil` is returned.

```swift
let value = try! Yaml.load("languages:\n - Swift: true\n - Objective C: false")[0]
print(value.array)  // nil
print(value["languages"].array)  // Optional([dictionary([string(Swift): bool(true)]), dictionary([string(Objective C): bool(false)])])
```





### Yaml#dictionary

```swift
value.dictionary -> [Yaml: Yaml]?
```

Returns an `Optional<Dictionary<Yaml, Yaml>>` value. If the value is a `Yaml.dictionary` value, the wrapped value is returned. Otherwise `nil` is returned.

```swift
let value = try! Yaml.load("- Swift: true\n- Objective C: false")[0]
print(value.dictionary)  // nil
print(value[0].dictionary)  // Optional([string(Swift): bool(true)])
```





### Yaml#count

```swift
value.count -> Int?
```

Returns an `Optional<Int>` value. If the value is either a `Yaml.array` or a `Yaml.dictionary` value, the count of elements is returned. Otherwise `nil` is returned.

```swift
let value = try! Yaml.load("- Swift: true\n- Objective C: false")[0]
print(value.count)  // Optional(2)
print(value[0].count)  // Optional(1)
print(value[0]["Swift"].count)  // nil
```





## License

MIT
