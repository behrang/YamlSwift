import XCTest

@testable import YamlTests

XCTMain([
  testCase(ExampleTests.allTests),
  testCase(YamlTests.allTests),
])
