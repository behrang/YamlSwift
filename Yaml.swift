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
    var array = [Yaml]()
    array.reserveCapacity(elements.count)
    for element in elements {
      array.append(element)
    }
    self = .Array(array)
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

extension Yaml: Printable {
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
  public static func load (text: Swift.String) -> Result<Yaml> {
    return tokenize(text) >>=- parseDoc
  }

  public static func loadMultiple (text: Swift.String) -> Result<[Yaml]> {
    return tokenize(text) >>=- parseDocs
  }

  public static func debug (text: Swift.String) -> Result<Yaml> {
    let result = tokenize(text)
        >>- { tokens in println("\n====== Tokens:\n\(tokens)"); return tokens }
        >>=- parseDoc
        >>- { value -> Yaml in println("------ Doc:\n\(value)"); return value }
    if let error = result.error {
      println("~~~~~~\n\(error)")
    }
    return result
  }

  public static func debugMultiple (text: Swift.String) -> Result<[Yaml]> {
    let result = tokenize(text)
        >>- { tokens in println("\n====== Tokens:\n\(tokens)"); return tokens }
        >>=- parseDocs
        >>- { values -> [Yaml] in values.map {
              v in println("------ Doc:\n\(v)")
            }; return values }
    if let error = result.error {
      println("~~~~~~\n\(error)")
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
        if index >= array.startIndex && index < array.endIndex {
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
      case .Array(var array):
        let emptyCount = max(0, index + 1 - array.count)
        let empty = [Yaml](count: emptyCount, repeatedValue: .Null)
        array.extend(empty)
        array[index] = newValue
        self = .Array(array)
      default:
        var array = [Yaml](count: index + 1, repeatedValue: .Null)
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
      case .Dictionary(var dictionary):
        dictionary[key] = newValue
        self = .Dictionary(dictionary)
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
  switch lhs {

  case .Null:
    switch rhs {
    case .Null:
      return true
    default:
      return false
    }

  case .Bool(let lv):
    switch rhs {
    case .Bool(let rv):
      return lv == rv
    default:
      return false
    }

  case .Int(let lv):
    switch rhs {
    case .Int(let rv):
      return lv == rv
    case .Double(let rv):
      return Double(lv) == rv
    default:
      return false
    }

  case .Double(let lv):
    switch rhs {
    case .Double(let rv):
      return lv == rv
    case .Int(let rv):
      return lv == Double(rv)
    default:
      return false
    }

  case .String(let lv):
    switch rhs {
    case .String(let rv):
      return lv == rv
    default:
      return false
    }

  case .Array(let lv):
    switch rhs {
    case .Array(let rv) where lv.count == rv.count:
      for i in 0..<lv.count {
        if lv[i] != rv[i] {
          return false
        }
      }
      return true
    default:
      return false
    }

  case .Dictionary(let lv):
    switch rhs {
    case .Dictionary(let rv) where lv.count == rv.count:
      for (k, v) in lv {
        if rv[k] == nil || rv[k] != v {
          return false
        }
      }
      return true
    default:
      return false
    }
  }
}

public func != (lhs: Yaml, rhs: Yaml) -> Bool {
  return !(lhs == rhs)
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
