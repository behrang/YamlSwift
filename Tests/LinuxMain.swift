import XCTest

@testable import YamlTestSuite

XCTMain([
  testCase(ExampleTests.allTests),
  testCase(YamlTests.allTests),
])
