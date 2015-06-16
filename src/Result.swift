public enum Result<T> {
  case Error(String)
  case Value(Box<T>)

  public var error: String? {
    switch self {
    case .Error(let e): return e
    case .Value: return nil
    }
  }

  public var value: T? {
    switch self {
    case .Error: return nil
    case .Value(let v): return v.value
    }
  }

  public func map <U> (f: T -> U) -> Result<U> {
    switch self {
    case .Error(let e): return .Error(e)
    case .Value(let v): return .Value(Box(f(v.value)))
    }
  }

  public func flatMap <U> (f: T -> Result<U>) -> Result<U> {
    switch self {
    case .Error(let e): return .Error(e)
    case .Value(let v): return f(v.value)
    }
  }
}

infix operator <*> { associativity left }
func <*> <T, U> (f: Result<T -> U>, x: Result<T>) -> Result<U> {
  switch (x, f) {
  case (.Error(let e), _): return .Error(e)
  case (.Value, .Error(let e)): return .Error(e)
  case (.Value(let x), .Value(let f)): return .Value(Box(f.value(x.value)))
  }
}

infix operator <^> { associativity left }
func <^> <T, U> (f: T -> U, x: Result<T>) -> Result<U> {
  return x.map(f)
}

infix operator >>- { associativity left }
func >>- <T, U> (x: Result<T>, f: T -> U) -> Result<U> {
  return x.map(f)
}

infix operator >>=- { associativity left }
func >>=- <T, U> (x: Result<T>, f: T -> Result<U>) -> Result<U> {
  return x.flatMap(f)
}

infix operator >>| { associativity left }
func >>| <T, U> (x: Result<T>, y: Result<U>) -> Result<U> {
  return x.flatMap { _ in y }
}

func lift <V> (v: V) -> Result<V> {
  return .Value(Box(v))
}

func fail <T> (e: String) -> Result<T> {
  return .Error(e)
}

func join <T> (x: Result<Result<T>>) -> Result<T> {
  return x >>=- { i in i }
}

func `guard` (@autoclosure error: () -> String) (check: Bool) -> Result<()> {
  return check ? lift(()) : .Error(error())
}

// Required for boxing for now.
public class Box<T> {
  let _value: () -> T

  init(_ value: T) {
    _value = { value }
  }

  var value: T {
    return _value()
  }
}
