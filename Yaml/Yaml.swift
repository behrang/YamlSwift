import Parsec

public enum Yaml {
  case null
  case bool(Bool)
  case int(Int)
  case double(Double)
  case string(String)
  case array([Yaml])
  case dictionary([Yaml: Yaml])
}

public enum YamlError: Error, CustomStringConvertible {
  case message(String)

  public var description: String {
    switch self {
    case .message(let error): return error
    }
  }
}

extension Yaml {
  public static func load (_ text: String, schema: Schema = core_schema) throws -> [Yaml] {
    switch parse(l_yaml_stream <<< eof, schema, "", text.characters) {
      case let .left(err): throw YamlError.message(err.description)
      case let .right(value):
        let node = Node.sequence(value, tag_sequence)
        return try node.construct(schema.resolve).array!
    }
  }
}

extension Yaml {
  public var bool: Bool? {
    switch self {
    case .bool(let b):
      return b
    default:
      return nil
    }
  }

  public var int: Int? {
    switch self {
    case .int(let i):
      return i
    case .double(let f):
      if Double(Int(f)) == f {
        return Int(f)
      } else {
        return nil
      }
    default:
      return nil
    }
  }

  public var double: Double? {
    switch self {
    case .double(let f):
      return f
    case .int(let i):
      return Double(i)
    default:
      return nil
    }
  }

  public var string: String? {
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

  public var count: Int? {
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
  public var description: String {
    switch self {
    case .null: return "null()"
    case .bool(let b): return "bool(\(b))"
    case .int(let i): return "int(\(i))"
    case .double(let f): return "double(\(f))"
    case .string(let s): return "string(\(s))"
    case .array(let s): return "array(\(s))"
    case .dictionary(let m): return "dictionary(\(m))"
    }
  }
}

extension Yaml: Hashable {
  public var hashValue: Int {
    return description.hashValue
  }
}

extension Yaml {
  public subscript(index: Int) -> Yaml {
    get {
      assert(index >= 0)
      switch self {
      case .array(let array):
        if index >= array.startIndex && index < array.endIndex {
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

extension Yaml: Equatable {
  public static func == (lhs: Yaml, rhs: Yaml) -> Bool {
    let x = (lhs, rhs)
    switch x {
      case (.null, .null): return true
      case let (.bool(lv), .bool(rv)): return lv == rv
      case let (.int(lv), .int(rv)): return lv == rv
      case let (.double(lv), .double(rv)): return lv == rv
      case let (.int(lv), .double(rv)): return Double(lv) == rv
      case let (.double(lv), .int(rv)): return lv == Double(rv)
      case let (.string(lv), .string(rv)): return lv == rv
      case let (.array(lv), .array(rv)): return lv == rv
      case let (.dictionary(lv), .dictionary(rv)): return lv == rv
      default: return false
    }
  }
}

// unary `-` operator
public prefix func - (value: Yaml) -> Yaml {
  switch value {
  case .int(let v):
    return .int(-v)
  case .double(let v):
    return .double(-v)
  default:
    fatalError("`-` operator may only be used on .int or .double Yaml values")
  }
}
