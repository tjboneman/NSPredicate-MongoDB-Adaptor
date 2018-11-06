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
        let components = and.compactMap({ $0.first })
        XCTAssertEqual(components.filter({ $0.key == "name" }).first?.value as? String, "Victor")
        let _age = components.filter({ $0.key == "age" }).first?.value as? [String : Any]
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
    
    func testAndCannotOptimize() {
        let predicate = NSPredicate(format: "age > %@ AND age < %@", NSNumber(value: 18), NSNumber(value: 21))
        let _mongoDBQuery = predicate.mongoDBQuery
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
        let components = and.compactMap({ $0.first })
            .filter({ $0.key == "age" })
            .compactMap({ $0.value as? [String : Int] })
            .compactMap({ $0.first })
        let gt = components.filter({ $0.key == "$gt" }).first?.value
        let lt = components.filter({ $0.key == "$lt" }).first?.value
        XCTAssertEqual(gt, 18)
        XCTAssertEqual(lt, 21)
    }

    static var allTests = [
        ("testAndNotOptimized", testAndNotOptimized),
        ("testAndOptimized", testAndOptimized),
        ("testAndCannotOptimize", testAndCannotOptimize),
    ]

}
