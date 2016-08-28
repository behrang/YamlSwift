import XCTest
import Parsec

func left<a> (_ p: StringParserClosure<a>, _ input: String,
    file: StaticString = #file, line: UInt = #line)
{
  switch parse(p, "", input.characters) {
  case .left: return
  case let .right(x):
    XCTFail("expected left but got .right(\(x))", file: file, line: line)
  }
}

func right<a: Equatable> (_ p: StringParserClosure<a>, _ input: String, _ exp: a,
    file: StaticString = #file, line: UInt = #line)
{
  switch parse(p, "", input.characters) {
  case let .left(err): XCTFail(err.description, file: file, line: line)
  case let .right(act): XCTAssertEqual(exp, act, file: file, line: line)
  }
}

func right (_ p: StringParserClosure<[String]>, _ input: String, _ exp: [String],
    file: StaticString = #file, line: UInt = #line)
{
  switch parse(p, "", input.characters) {
  case let .left(err): XCTFail(err.description, file: file, line: line)
  case let .right(act): XCTAssertTrue(exp == act, file: file, line: line)
  }
}

func right (_ p: StringParserClosure<(String, [String])>, _ input: String,
  _ exp: (String, [String]),
  file: StaticString = #file, line: UInt = #line)
{
  switch parse(p, "", input.characters) {
  case let .left(err): XCTFail(err.description, file: file, line: line)
  case let .right(s, ss):
    XCTAssertTrue(exp.0 == s && exp.1 == ss, file: file, line: line)
  }
}

func right (_ p: StringParserClosure<()>, _ input: String,
  file: StaticString = #file, line: UInt = #line)
{
  switch parse(p, "", input.characters) {
  case let .left(err): XCTFail(err.description, file: file, line: line)
  case .right: return
  }
}
