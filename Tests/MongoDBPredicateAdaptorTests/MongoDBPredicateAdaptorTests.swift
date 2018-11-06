import XCTest

@testable import MongoDBPredicateAdaptor

class MongoDBPredicateAdaptorTests: XCTestCase {
    
    func testAndNotOptimized() {
        let predicate = NSPredicate(format: "name == %@ AND age > %@", "Victor", NSNumber(value: 18))
        let _mongoDBQuery = predicate.mongoDBQuery(optimize: false)
        guard let mongoDBQuery = _mongoDBQuery else {
            XCTAssertNotNil(_mongoDBQuery)
            return
        }
        XCTAssertEqual(mongoDBQuery.count, 1)
        let _and = mongoDBQuery["$and"] as? [[String : Any]]
        guard let and = _and else {
            XCTAssertNotNil(_and)
            return
        }
        XCTAssertEqual(and.count, 2)
        XCTAssertEqual(and.filter({ $0.first?.key == "name" }).first?.values.first as? String, "Victor")
        let _age = and.filter({ $0.first?.key == "age" }).first?.values.first as? [String : Any]
        guard let age = _age else {
            XCTAssertNotNil(_age)
            return
        }
        XCTAssertEqual(age.count, 1)
        XCTAssertEqual(age["$gt"] as? Int, 18)
    }
    
    func testAndOptimized() {
        let predicate = NSPredicate(format: "name == %@ AND age > %@", "Victor", NSNumber(value: 18))
        let _mongoDBQuery = predicate.mongoDBQuery
        guard let mongoDBQuery = _mongoDBQuery else {
            XCTAssertNotNil(_mongoDBQuery)
            return
        }
        XCTAssertEqual(mongoDBQuery.count, 2)
        XCTAssertEqual(mongoDBQuery["name"] as? String, "Victor")
        let _age = mongoDBQuery["age"] as? [String : Any]
        guard let age = _age else {
            XCTAssertNotNil(_age)
            return
        }
        XCTAssertEqual(age.count, 1)
        XCTAssertEqual(age["$gt"] as? Int, 18)
    }

    static var allTests = [
        ("testAndNotOptimized", testAndNotOptimized),
        ("testAndOptimized", testAndOptimized),
    ]

}
