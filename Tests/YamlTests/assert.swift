import XCTest
import Parsec
@testable
import Yaml

func left<a> (_ p: YamlParserClosure<a>, _ input: String,
    file: StaticString = #file, line: UInt = #line)
{
  switch parse(p, YamlState(), "", input.characters) {
  case .left: return
  case let .right(x):
    XCTFail("expected left but got .right(\(x))", file: file, line: line)
  }
}

func right<a: Equatable> (_ p: YamlParserClosure<a>, _ input: String, _ exp: a,
    file: StaticString = #file, line: UInt = #line)
{
  switch parse(p, YamlState(), "", input.characters) {
  case let .left(err): XCTFail(err.description, file: file, line: line)
  case let .right(act): XCTAssertEqual(exp, act, file: file, line: line)
  }
}

func right (_ p: YamlParserClosure<[String]>, _ input: String, _ exp: [String],
    file: StaticString = #file, line: UInt = #line)
{
  switch parse(p, YamlState(), "", input.characters) {
  case let .left(err): XCTFail(err.description, file: file, line: line)
  case let .right(act): XCTAssertTrue(exp == act, file: file, line: line)
  }
}

func right (_ p: YamlParserClosure<[Node]>, _ input: String, _ exp: [Node],
    file: StaticString = #file, line: UInt = #line)
{
  switch parse(p, YamlState(), "", input.characters) {
  case let .left(err): XCTFail(err.description, file: file, line: line)
  case let .right(act): XCTAssertTrue(exp == act, file: file, line: line)
  }
}

func right (_ p: YamlParserClosure<(tag: String?, anchor: String?)>, _ input: String,
    _ exp: (tag: String?, anchor: String?),
    file: StaticString = #file, line: UInt = #line)
{
  switch parse(p, YamlState(), "", input.characters) {
  case let .left(err): XCTFail(err.description, file: file, line: line)
  case let .right(act):
    XCTAssertTrue(exp.0 == act.0 && exp.1 == act.1, file: file, line: line)
  }
}

func right (_ p: YamlParserClosure<(String, [String])>, _ input: String,
  _ exp: (String, [String]),
  file: StaticString = #file, line: UInt = #line)
{
  switch parse(p, YamlState(), "", input.characters) {
  case let .left(err): XCTFail(err.description, file: file, line: line)
  case let .right(s, ss):
    XCTAssertTrue(exp.0 == s && exp.1 == ss, file: file, line: line)
  }
}

func right (_ p: YamlParserClosure<(indent: Int, chomp: Chomp)>, _ input: String,
  _ exp: (indent: Int, chomp: Chomp),
  file: StaticString = #file, line: UInt = #line)
{
  switch parse(p, YamlState(), "", input.characters) {
  case let .left(err): XCTFail(err.description, file: file, line: line)
  case let .right(n, t):
    XCTAssertTrue(exp.0 == n && exp.1 == t, file: file, line: line)
  }
}

func right (_ p: YamlParserClosure<()>, _ input: String,
  file: StaticString = #file, line: UInt = #line)
{
  switch parse(p, YamlState(), "", input.characters) {
  case let .left(err): XCTFail(err.description, file: file, line: line)
  case .right: return
  }
}
