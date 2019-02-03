import XCTest

extension ReteEngineTests {
    static let __allTests = [
        ("testDuplicate", testDuplicate),
        ("testMultiProductions", testMultiProductions),
        ("testNetwork", testNetwork),
        ("testProductionItems", testProductionItems),
    ]
}

#if !os(macOS)
public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(ReteEngineTests.__allTests),
    ]
}
#endif
