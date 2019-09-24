import XCTest

import echoSocketServerTests

var tests = [XCTestCaseEntry]()
tests += echoSocketServerTests.allTests()
XCTMain(tests)
