public enum Yaml: Hashable, Printable {

  case Null
  case Bool(Swift.Bool)
  case Int(Swift.Int)
  case Float(Swift.Float)
  case String(Swift.String)
  case Seq([Yaml])
  case Map([Yaml: Yaml])
  case Invalid(Swift.String)

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
    return .Seq(docs)
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
    case .Float(let f):
      if Swift.Float(Swift.Int(f)) == f {
        return Swift.Int(f)
      } else {
        return nil
      }
    default:
      return nil
    }
  }

  public var float: Swift.Float? {
    switch self {
    case .Float(let f):
      return f
    case .Int(let i):
      return Swift.Float(i)
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
    case .Seq(let seq):
      return seq
    default:
      return nil
    }
  }

  public var map: [Yaml: Yaml]? {
    switch self {
    case .Map(let map):
      return map
    default:
      return nil
    }
  }

  public var count: Swift.Int? {
    switch self {
    case .Seq(let seq):
      return seq.count
    case .Map(let map):
      return map.count
    default:
      return nil
    }
  }

  public subscript(index: Swift.Int) -> Yaml {
    get {
      switch self {
      case .Seq(let seq):
        if index >= seq.startIndex && index < seq.endIndex {
          return seq[index]
        } else {
          return .Null
        }
      default:
        return .Null
      }
    }
  }

  public subscript(key: Swift.String) -> Yaml {
    get {
      switch self {
      case .Map(let map):
        return map[.String(key)] ?? .Null
      default:
        return .Null
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
    case .Float(let f):
      return "Float(\(f))"
    case .String(let s):
      return "String(\(s))"
    case .Seq(let s):
      return "Seq(\(s))"
    case .Map(let m):
      return "Map(\(m))"
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
    default:
      return false
    }

  case .Float(let lv):
    switch rhs {
    case .Float(let rv):
      return lv == rv || lv.isNaN && rv.isNaN
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

  case .Seq(let lv):
    switch rhs {
    case .Seq(let rv) where lv.count == rv.count:
      for i in 0..<lv.count {
        if lv[i] != rv[i] {
          return false
        }
      }
      return true
    default:
      return false
    }

  case .Map(let lv):
    switch rhs {
    case .Map(let rv) where lv.count == rv.count:
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
