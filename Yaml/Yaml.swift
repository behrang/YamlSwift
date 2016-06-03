public enum Yaml {
  case Null
  case Bool(Swift.Bool)
  case Int(Swift.Int)
  case Double(Swift.Double)
  case String(Swift.String)
  case Array([Yaml])
  case Dictionary([Yaml: Yaml])
}

extension Yaml: NilLiteralConvertible {
  public init(nilLiteral: ()) {
    self = .Null
  }
}

extension Yaml: BooleanLiteralConvertible {
  public init(booleanLiteral: BooleanLiteralType) {
    self = .Bool(booleanLiteral)
  }
}

extension Yaml: IntegerLiteralConvertible {
  public init(integerLiteral: IntegerLiteralType) {
    self = .Int(integerLiteral)
  }
}

extension Yaml: FloatLiteralConvertible {
  public init(floatLiteral: FloatLiteralType) {
    self = .Double(floatLiteral)
  }
}

extension Yaml: StringLiteralConvertible {
  public init(stringLiteral: StringLiteralType) {
    self = .String(stringLiteral)
  }

  public init(extendedGraphemeClusterLiteral: StringLiteralType) {
    self = .String(extendedGraphemeClusterLiteral)
  }

  public init(unicodeScalarLiteral: StringLiteralType) {
    self = .String(unicodeScalarLiteral)
  }
}

extension Yaml: ArrayLiteralConvertible {
  public init(arrayLiteral elements: Yaml...) {
    self = .Array(elements)
  }
}

extension Yaml: DictionaryLiteralConvertible {
  public init(dictionaryLiteral elements: (Yaml, Yaml)...) {
    var dictionary = [Yaml: Yaml]()
    for (k, v) in elements {
      dictionary[k] = v
    }
    self = .Dictionary(dictionary)
  }
}

extension Yaml: CustomStringConvertible {
  public var description: Swift.String {
    switch self {
    case .Null:
      return "Null"
    case .Bool(let b):
      return "Bool(\(b))"
    case .Int(let i):
      return "Int(\(i))"
    case .Double(let f):
      return "Double(\(f))"
    case .String(let s):
      return "String(\(s))"
    case .Array(let s):
      return "Array(\(s))"
    case .Dictionary(let m):
      return "Dictionary(\(m))"
    }
  }
}

extension Yaml: Hashable {
  public var hashValue: Swift.Int {
    return description.hashValue
  }
}

extension Yaml {
  public static func load (_ text: Swift.String) -> Result<Yaml> {
    return tokenize(text) >>=- parseDoc
  }

  public static func loadMultiple (_ text: Swift.String) -> Result<[Yaml]> {
    return tokenize(text) >>=- parseDocs
  }

  public static func debug (_ text: Swift.String) -> Result<Yaml> {
    let result = tokenize(text)
        >>- { tokens in print("\n====== Tokens:\n\(tokens)"); return tokens }
        >>=- parseDoc
        >>- { value -> Yaml in print("------ Doc:\n\(value)"); return value }
    if let error = result.error {
      print("~~~~~~\n\(error)")
    }
    return result
  }

  public static func debugMultiple (_ text: Swift.String) -> Result<[Yaml]> {
    let result = tokenize(text)
        >>- { tokens in print("\n====== Tokens:\n\(tokens)"); return tokens }
        >>=- parseDocs
        >>- { values -> [Yaml] in values.forEach {
              v in print("------ Doc:\n\(v)")
            }; return values }
    if let error = result.error {
      print("~~~~~~\n\(error)")
    }
    return result
  }
}

extension Yaml {
  public subscript(index: Swift.Int) -> Yaml {
    get {
      assert(index >= 0)
      switch self {
      case .Array(let array):
        if array.indices.contains(index) {
          return array[index]
        } else {
          return .Null
        }
      default:
        return .Null
      }
    }
    set {
      assert(index >= 0)
      switch self {
      case .Array(let array):
        let emptyCount = max(0, index + 1 - array.count)
        let empty = [Yaml](repeating: .Null, count: emptyCount)
        var new = array
        new.append(contentsOf: empty)
        new[index] = newValue
        self = .Array(new)
      default:
        var array = [Yaml](repeating: .Null, count: index + 1)
        array[index] = newValue
        self = .Array(array)
      }
    }
  }

  public subscript(key: Yaml) -> Yaml {
    get {
      switch self {
      case .Dictionary(let dictionary):
        return dictionary[key] ?? .Null
      default:
        return .Null
      }
    }
    set {
      switch self {
      case .Dictionary(let dictionary):
        var new = dictionary
        new[key] = newValue
        self = .Dictionary(new)
      default:
        var dictionary = [Yaml: Yaml]()
        dictionary[key] = newValue
        self = .Dictionary(dictionary)
      }
    }
  }
}

extension Yaml {
  public var bool: Swift.Bool? {
    switch self {
    case .Bool(let b):
      return b
    default:
      return nil
    }
  }

  public var int: Swift.Int? {
    switch self {
    case .Int(let i):
      return i
    case .Double(let f):
      if Swift.Double(Swift.Int(f)) == f {
        return Swift.Int(f)
      } else {
        return nil
      }
    default:
      return nil
    }
  }

  public var double: Swift.Double? {
    switch self {
    case .Double(let f):
      return f
    case .Int(let i):
      return Swift.Double(i)
    default:
      return nil
    }
  }

  public var string: Swift.String? {
    switch self {
    case .String(let s):
      return s
    default:
      return nil
    }
  }

  public var array: [Yaml]? {
    switch self {
    case .Array(let array):
      return array
    default:
      return nil
    }
  }

  public var dictionary: [Yaml: Yaml]? {
    switch self {
    case .Dictionary(let dictionary):
      return dictionary
    default:
      return nil
    }
  }

  public var count: Swift.Int? {
    switch self {
    case .Array(let array):
      return array.count
    case .Dictionary(let dictionary):
      return dictionary.count
    default:
      return nil
    }
  }
}

public func == (lhs: Yaml, rhs: Yaml) -> Bool {
  switch (lhs, rhs) {
  case (.Null, .Null):
    return true
  case (.Bool(let lv), .Bool(let rv)):
    return lv == rv
  case (.Int(let lv), .Int(let rv)):
    return lv == rv
  case (.Int(let lv), .Double(let rv)):
    return Double(lv) == rv
  case (.Double(let lv), .Double(let rv)):
    return lv == rv
  case (.Double(let lv), .Int(let rv)):
    return lv == Double(rv)
  case (.String(let lv), .String(let rv)):
    return lv == rv
  case (.Array(let lv), .Array(let rv)):
    return lv == rv
  case (.Dictionary(let lv), .Dictionary(let rv)):
    return lv == rv
  default:
    return false
  }
}

// unary `-` operator
public prefix func - (value: Yaml) -> Yaml {
  switch value {
  case .Int(let v):
    return .Int(-v)
  case .Double(let v):
    return .Double(-v)
  default:
    fatalError("`-` operator may only be used on .Int or .Double Yaml values")
  }
}
