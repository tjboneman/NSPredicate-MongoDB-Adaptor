import XCTest

#if !os(macOS) && !os(iOS) && !os(tvOS)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(MongoDBPredicateAdaptorTests.allTests),
    ]
}
#endif
