import Foundation

public enum Yaml {
  case null
  case bool(Swift.Bool)
  case int(Swift.Int)
  case double(Swift.Double)
  case string(Swift.String)
  case array([Yaml])
  case dictionary([Yaml: Yaml])
    
    static public func == (lhs: Yaml, rhs: Yaml) -> Bool {
        switch (lhs, rhs) {
        case (.null, .null):
            return true
        case (.bool(let lv), .bool(let rv)):
            return lv == rv
        case (.int(let lv), .int(let rv)):
            return lv == rv
        case (.int(let lv), .double(let rv)):
            return Double(lv) == rv
        case (.double(let lv), .double(let rv)):
            return lv == rv
        case (.double(let lv), .int(let rv)):
            return lv == Double(rv)
        case (.string(let lv), .string(let rv)):
            return lv == rv
        case (.array(let lv), .array(let rv)):
            return lv == rv
        case (.dictionary(let lv), .dictionary(let rv)):
            return lv == rv
        default:
            return false
        }
    }
    
    // unary `-` operator
    static public prefix func - (value: Yaml) -> Yaml {
        switch value {
        case .int(let v):
            return .int(-v)
        case .double(let v):
            return .double(-v)
        default:
            fatalError("`-` operator may only be used on .int or .double Yaml values")
        }
    }
}

extension Yaml: ExpressibleByNilLiteral {
  public init(nilLiteral: ()) {
    self = .null
  }
}

extension Yaml: ExpressibleByBooleanLiteral {
  public init(booleanLiteral: BooleanLiteralType) {
    self = .bool(booleanLiteral)
  }
}

extension Yaml: ExpressibleByIntegerLiteral {
  public init(integerLiteral: IntegerLiteralType) {
    self = .int(integerLiteral)
  }
}

extension Yaml: ExpressibleByFloatLiteral {
  public init(floatLiteral: FloatLiteralType) {
    self = .double(floatLiteral)
  }
}

extension Yaml: ExpressibleByStringLiteral {
  public init(stringLiteral: StringLiteralType) {
    self = .string(stringLiteral)
  }

  public init(extendedGraphemeClusterLiteral: StringLiteralType) {
    self = .string(extendedGraphemeClusterLiteral)
  }

  public init(unicodeScalarLiteral: StringLiteralType) {
    self = .string(unicodeScalarLiteral)
  }
}

extension Yaml: ExpressibleByArrayLiteral {
  public init(arrayLiteral elements: Yaml...) {
    self = .array(elements)
  }
}

extension Yaml: ExpressibleByDictionaryLiteral {
  public init(dictionaryLiteral elements: (Yaml, Yaml)...) {
    var dictionary = [Yaml: Yaml]()
    for (k, v) in elements {
      dictionary[k] = v
    }
    self = .dictionary(dictionary)
  }
}

extension Yaml: CustomStringConvertible {
  public var description: Swift.String {
    switch self {
    case .null:
      return "Null"
    case .bool(let b):
      return "Bool(\(b))"
    case .int(let i):
      return "Int(\(i))"
    case .double(let f):
      return "Double(\(f))"
    case .string(let s):
      return "String(\(s))"
    case .array(let s):
      return "Array(\(s))"
    case .dictionary(let m):
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
      case .array(let array):
        if array.indices.contains(index) {
          return array[index]
        } else {
          return .null
        }
      default:
        return .null
      }
    }
    set {
      assert(index >= 0)
      switch self {
      case .array(let array):
        let emptyCount = max(0, index + 1 - array.count)
        let empty = [Yaml](repeating: .null, count: emptyCount)
        var new = array
        new.append(contentsOf: empty)
        new[index] = newValue
        self = .array(new)
      default:
        var array = [Yaml](repeating: .null, count: index + 1)
        array[index] = newValue
        self = .array(array)
      }
    }
  }

  public subscript(key: Yaml) -> Yaml {
    get {
      switch self {
      case .dictionary(let dictionary):
        return dictionary[key] ?? .null
      default:
        return .null
      }
    }
    set {
      switch self {
      case .dictionary(let dictionary):
        var new = dictionary
        new[key] = newValue
        self = .dictionary(new)
      default:
        var dictionary = [Yaml: Yaml]()
        dictionary[key] = newValue
        self = .dictionary(dictionary)
      }
    }
  }
}

extension Yaml {
  public var bool: Swift.Bool? {
    switch self {
    case .bool(let b):
      return b
    default:
      return nil
    }
  }

  public var int: Swift.Int? {
    switch self {
    case .int(let i):
      return i
    case .double(let f):
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
    case .double(let f):
      return f
    case .int(let i):
      return Swift.Double(i)
    default:
      return nil
    }
  }

  public var string: Swift.String? {
    switch self {
    case .string(let s):
      return s
    default:
      return nil
    }
  }

  public var array: [Yaml]? {
    switch self {
    case .array(let array):
      return array
    default:
      return nil
    }
  }

  public var dictionary: [Yaml: Yaml]? {
    switch self {
    case .dictionary(let dictionary):
      return dictionary
    default:
      return nil
    }
  }

  public var count: Swift.Int? {
    switch self {
    case .array(let array):
      return array.count
    case .dictionary(let dictionary):
      return dictionary.count
    default:
      return nil
    }
  }
}

