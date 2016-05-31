infix operator |> { associativity left }
func |> <T, U> (x: T, f: T -> U) -> U {
  return f(x)
}

func count(string: String) -> String.Index.Distance {
    return string.characters.count
}