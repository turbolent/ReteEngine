import XCTest

extension ReteEngineTests {
    static let __allTests = [
        ("testActionPatternSubstitution", testActionPatternSubstitution),
        ("testDuplicate", testDuplicate),
        ("testMultiProductions", testMultiProductions),
        ("testNetwork", testNetwork),
        ("testProductionItems", testProductionItems),
        ("testRuleAction", testRuleAction),
        ("testRuleParser", testRuleParser),
        ("testTokenBinding", testTokenBinding),
        ("testWMEParser", testWMEParser),
    ]
}

#if !os(macOS)
public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(ReteEngineTests.__allTests),
    ]
}
#endif
