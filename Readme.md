# Yaml.swift

Load [YAML](http://yaml.org) and [JSON](http://json.org) documents using [Swift](http://www.apple.com/swift/).

`Yaml.swift` parses a string of YAML document(s) (or a JSON document) and returns a `Yaml` enum value representing that string.





## Install

Currently, you have to build it manually. Download and then run this command:

```sh
make CONFIG=release
```

`Yaml.framework` will be created in `build/macosx/release` which you can add to your project.

To add to an Xcode project:

1. On your application targets' "General" tab, in the "Embedded Binaries" section, drag and drop the framework from the `build/macosx/release` folder.

2. On the `Build Settings` tab, in the "Swift Compiler - Search Paths" section, add the framework to `Import Paths`.

Then you should be able to use `import Yaml` and `Yaml.load("")`.

To run tests:

```sh
make test
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
  case Null
  case Bool(Bool)
  case Int(Int)
  case Double(Double)
  case String(String)
  case Array([Yaml])
  case Dictionary([Yaml: Yaml])
}
```





### Yaml.load

```swift
Yaml.load (String) -> Result<Yaml>
```

Takes a string of a YAML document and returns a `Result` of `Yaml` enum value.

```swift
let value = Yaml.load("a: 1\nb: 2").value!
println(value["a"])  // Int(1)
println(value["b"])  // Int(2)
println(value["c"])  // Null
```

If the input document is invalid or contains more than one YAML document, an error is returned.

```swift
let value = Yaml.load("a\nb: 2").error!
println(value)  // expected end, near "b: 2"
```





### Yaml.loadMultiple

```swift
Yaml.loadMultiple (String) -> Result<[Yaml]>
```

Takes a string of one or more YAML documents and returns a `Result` of `[Yaml]`.

```swift
let value = Yaml.loadMultiple("---\na: 1\nb: 2\n---\na: 3\nb: 4").value!
println(value[0]["a"])  // Int(1)
println(value[1]["a"])  // Int(3)
```

If an error is encountered in any of the documents, an error is returned.





### Yaml#[Int] -> Yaml

```swift
value[Int] -> Yaml
value[Int] = Yaml
```

If used on a `Yaml.Array` value, it will return the value at the specified index. If the index is invalid or the value is not a `Yaml.Array`, `Yaml.Null` is returned. You can also set a value at a specific index. Enough elements will be added to the wrapped array to set the specified index. If the value is not a `Yaml.Array`, it will change to it after set.

```swift
var value = Yaml.load("- Behrang\n- Maryam")
println(value[0])  // String(Behrang)
println(value[1])  // String(Maryam)
println(value[2])  // Null
value[2] = "Radin"
println(value[2])  // String(Radin)
```





### Yaml#[Yaml] -> Yaml

```swift
value[Yaml] -> Yaml
value[Yaml] = Yaml
```

If used on a `Yaml.Dictionary` value, it will return the value for the specified key. If a value for the specified key does not exist, or value is not a `Yaml.Dictionary`, `Yaml.Null` is returned. You can also set a value for a specific key. If the value is not a `Yaml.Dictionary`, it will change to it after set.

Since `Yaml` is a literal convertible type, you can pass simple values to this method.

```swift
var value = Yaml.load("first name: Behrang\nlast name: Noruzi Niya")
println(value["first name"])  // String(Behrang)
println(value["last name"])  // String(Noruzi Niya)
println(value["age"])  // Null
value["first name"] = "Radin"
value["age"] = 1
println(value["first name"])  // String(Radin)
println(value["last name"])  // String(Noruzi Niya)
println(value["age"])  // Int(1)
```





### Yaml#bool

```swift
value.bool -> Bool?
```

Returns an `Optional<Bool>` value. If the value is a `Yaml.Bool` value, the wrapped value is returned. Otherwise `nil` is returned.

```swift
let value = Yaml.load("animate: true\nshow tip: false\nusage: 25")
println(value["animate"].bool)  // Optional(true)
println(value["show tip"].bool)  // Optional(false)
println(value["usage"].bool)  // nil
```





### Yaml#int

```swift
value.int -> Int?
```

Returns an `Optional<Int>` value. If the value is a `Yaml.Int` value, the wrapped value is returned. Otherwise `nil` is returned.

```swift
let value = Yaml.load("a: 1\nb: 2.0\nc: 2.5")
println(value["a"].int)  // Optional(1)
println(value["b"].int)  // Optional(2)
println(value["c"].int)  // nil
```





### Yaml#double

```swift
value.double -> Double?
```

Returns an `Optional<Double>` value. If the value is a `Yaml.Double` value, the wrapped value is returned. Otherwise `nil` is returned.

```swift
let value = Yaml.load("a: 1\nb: 2.0\nc: 2.5\nd: true")
println(value["a"].double)  // Optional(1.0)
println(value["b"].double)  // Optional(2.0)
println(value["c"].double)  // Optional(2.5)
println(value["d"].double)  // nil
```





### Yaml#string

```swift
value.string -> String?
```

Returns an `Optional<String>` value. If the value is a `Yaml.String` value, the wrapped value is returned. Otherwise `nil` is returned.

```swift
let value = Yaml.load("first name: Behrang\nlast name: Noruzi Niya\nage: 33")
println(value["first name"].string)  // Optional("Behrang")
println(value["last name"].string)  // Optional("Noruzi Niya")
println(value["age"].string)  // nil
```





### Yaml#array

```swift
value.array -> [Yaml]?
```

Returns an `Optional<Array<Yaml>>` value. If the value is a `Yaml.Array` value, the wrapped value is returned. Otherwise `nil` is returned.

```swift
let value = Yaml.load("languages:\n - Swift: true\n - Objective C: false")
println(value.array)  // nil
println(value["languages"].array)  // Optional([Dictionary([String(Swift): Bool(true)]), Dictionary([String(Objective C): Bool(false)])])
```





### Yaml#dictionary

```swift
value.dictionary -> [Yaml: Yaml]?
```

Returns an `Optional<Dictionary<Yaml, Yaml>>` value. If the value is a `Yaml.Dictionary` value, the wrapped value is returned. Otherwise `nil` is returned.

```swift
let value = Yaml.load("- Swift: true\n- Objective C: false")
println(value.dictionary)  // nil
println(value[0].dictionary)  // Optional([String(Swift): Bool(true)])
```





### Yaml#count

```swift
value.count -> Int?
```

Returns an `Optional<Int>` value. If the value is either a `Yaml.Array` or a `Yaml.Dictionary` value, the count of elements is returned. Otherwise `nil` is returned.

```swift
let value = Yaml.load("- Swift: true\n- Objective C: false")
println(value.count)  // Optional(2)
println(value[0].count)  // Optional(1)
println(value[0]["Swift"].count)  // nil
```





## License

MIT
