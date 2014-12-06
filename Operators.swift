infix operator |> { associativity left }
func |> <T, U> (x: T, f: T -> U) -> U {
  return f(x)
}
