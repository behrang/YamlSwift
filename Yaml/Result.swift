public enum Result<T> {
  case Error(String)
  case Value(T)

  public var error: String? {
    switch self {
    case .Error(let e): return e
    case .Value: return nil
    }
  }

  public var value: T? {
    switch self {
    case .Error: return nil
    case .Value(let v): return v
    }
  }

  public func map <U> (f: (T) -> U) -> Result<U> {
    switch self {
    case .Error(let e): return .Error(e)
    case .Value(let v): return .Value(f(v))
    }
  }

  public func flatMap <U> (f: (T) -> Result<U>) -> Result<U> {
    switch self {
    case .Error(let e): return .Error(e)
    case .Value(let v): return f(v)
    }
  }
}

infix operator <*> { associativity left }
func <*> <T, U> (f: Result<(T) -> U>, x: Result<T>) -> Result<U> {
  switch (x, f) {
  case (.Error(let e), _): return .Error(e)
  case (.Value, .Error(let e)): return .Error(e)
  case (.Value(let x), .Value(let f)): return .Value(f(x))
  }
}

infix operator <^> { associativity left }
func <^> <T, U> (f: (T) -> U, x: Result<T>) -> Result<U> {
  return x.map(f: f)
}

infix operator >>- { associativity left }
func >>- <T, U> (x: Result<T>, f: (T) -> U) -> Result<U> {
  return x.map(f: f)
}

infix operator >>=- { associativity left }
func >>=- <T, U> (x: Result<T>, f: (T) -> Result<U>) -> Result<U> {
  return x.flatMap(f: f)
}

infix operator >>| { associativity left }
func >>| <T, U> (x: Result<T>, y: Result<U>) -> Result<U> {
  return x.flatMap { _ in y }
}

func lift <V> (_ v: V) -> Result<V> {
  return .Value(v)
}

func fail <T> (_ e: String) -> Result<T> {
  return .Error(e)
}

func join <T> (_ x: Result<Result<T>>) -> Result<T> {
  return x >>=- { i in i }
}

func `guard` (_ error: @autoclosure() -> String, check: Bool) -> Result<()> {
  return check ? lift(()) : .Error(error())
}
