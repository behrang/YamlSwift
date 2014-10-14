public enum Yaml:
    Hashable,
    Printable,
    BooleanLiteralConvertible,
    IntegerLiteralConvertible,
    FloatLiteralConvertible,
    StringLiteralConvertible,
    ArrayLiteralConvertible,
    DictionaryLiteralConvertible {

  case Null
  case Bool(Swift.Bool)
  case Int(Swift.Int)
  case Double(Swift.Double)
  case String(Swift.String)
  case Array([Yaml])
  case Dictionary([Yaml: Yaml])
  case Invalid(Swift.String)

  public init(booleanLiteral: BooleanLiteralType) {
    self = .Bool(booleanLiteral)
  }

  public init(integerLiteral: IntegerLiteralType) {
    self = .Int(integerLiteral)
  }

  public init(floatLiteral: FloatLiteralType) {
    self = .Double(floatLiteral)
  }

  public init(stringLiteral: StringLiteralType) {
    self = .String(stringLiteral)
  }

  public typealias ExtendedGraphemeClusterLiteralType = StringLiteralType
  public init(extendedGraphemeClusterLiteral: ExtendedGraphemeClusterLiteralType) {
    self = .String(extendedGraphemeClusterLiteral)
  }

  public typealias UnicodeScalarLiteralType = StringLiteralType
  public init(unicodeScalarLiteral: UnicodeScalarLiteralType) {
    self = .String(unicodeScalarLiteral)
  }

  public init(arrayLiteral elements: Yaml...) {
    var array = [Yaml]()
    array.reserveCapacity(elements.count)
    for element in elements {
      array.append(element)
    }
    self = .Array(array)
  }

  public init(dictionaryLiteral elements: (Yaml, Yaml)...) {
    var dictionary = [Yaml: Yaml]()
    for (k, v) in elements {
      dictionary[k] = v
    }
    self = .Dictionary(dictionary)
  }

  public static func load (text: Swift.String) -> Yaml {
    let result = tokenize(text)
    if let error = result.error {
      // println("Error: \(error)")
      return .Invalid(error)
    }
    // println(result.tokens!)
    let parser = Parser(result.tokens!)
    parser.ignoreSpace()
    parser.accept(.DocStart)
    let value = parser.parse()
    parser.ignoreDocEnd()
    if let error = parser.expect(.End, message: "expected end") {
      return .Invalid(error)
    }
    // println(value)
    return value
  }

  public static func loadMultiple (text: Swift.String) -> Yaml {
    let result = tokenize(text)
    if let error = result.error {
      // println("Error: \(error)")
      return .Invalid(error)
    }
    // println(result.tokens!)
    let parser = Parser(result.tokens!)
    parser.ignoreSpace()
    var docs: [Yaml] = []
    while parser.peek().type != .End {
      parser.accept(.DocStart)
      let value = parser.parse()
      switch value {
      case .Invalid:
        return value
      default:
        break
      }
      docs.append(value)
      parser.ignoreDocEnd()
    }
    // println(docs)
    return .Array(docs)
  }

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

  public var seq: [Yaml]? {
    switch self {
    case .Array(let seq):
      return seq
    default:
      return nil
    }
  }

  public var map: [Yaml: Yaml]? {
    switch self {
    case .Dictionary(let map):
      return map
    default:
      return nil
    }
  }

  public var count: Swift.Int? {
    switch self {
    case .Array(let seq):
      return seq.count
    case .Dictionary(let map):
      return map.count
    default:
      return nil
    }
  }

  public subscript(index: Swift.Int) -> Yaml {
    get {
      assert(index >= 0)
      switch self {
      case .Array(let seq):
        if index >= seq.startIndex && index < seq.endIndex {
          return seq[index]
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
      case .Array(var seq):
        seq.reserveCapacity(index + 1)
        while seq.count <= index {
          seq.append(.Null)
        }
        seq[index] = newValue
        self = .Array(seq)
      default:
        var seq = [Yaml](count: index + 1, repeatedValue: .Null)
        seq[index] = newValue
        self = .Array(seq)
      }
    }
  }

  public subscript(key: Swift.String) -> Yaml {
    get {
      switch self {
      case .Dictionary(let map):
        return map[.String(key)] ?? .Null
      default:
        return .Null
      }
    }
    set {
      switch self {
      case .Dictionary(var map):
        map[.String(key)] = newValue
        self = .Dictionary(map)
      default:
        var map = [Yaml: Yaml]()
        map[.String(key)] = newValue
        self = .Dictionary(map)
      }
    }
  }

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
    case .Invalid(let e):
      return "Invalid(\(e))"
    }
  }

  public var hashValue: Swift.Int {
    return description.hashValue
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
        if rv[k] == nil || rv[k]! != v {
          return false
        }
      }
      return true
    default:
      return false
    }

  case .Invalid(let lv):
    switch rhs {
    case .Invalid(let rv):
      return lv == rv
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
