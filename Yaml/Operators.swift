infix operator |> { associativity left }
func |> <T, U> (x: T, f: T -> U) -> U {
  return f(x)
}

func count<T:CollectionType>(collection: T) -> T.Index.Distance {
    return collection.count
}

func count(string: String) -> String.Index.Distance {
    return string.characters.count
}