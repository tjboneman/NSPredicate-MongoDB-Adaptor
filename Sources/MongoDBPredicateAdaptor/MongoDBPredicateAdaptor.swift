//
//  MongoDBPredicateAdaptor.swift
//  Kinvey
//
//  Created by Victor Hugo on 2017-02-02.
//  Copyright © 2017 Kinvey. All rights reserved.
//

import Foundation

#if canImport(MapKit)
    import MapKit
#endif

enum MongoDBOperator: String {
    
    //logical
    case not = "$not"
    case and = "$and"
    case or = "$or"
    
    //comparison
    case lessThan = "$lt"
    case lessThanOrEqualTo = "$lte"
    case greaterThan = "$gt"
    case greaterThanOrEqualTo = "$gte"
    case equalTo = "$eq"
    case notEqualTo = "$ne"
    case matches = "$regex"
    
    //array
    case `in` = "$in"
    case geoIn = "$geoWithin"
    
}

enum MongoDBJavaScriptOperator: String {
    
    //javascript comparison operators
    case lessThan = "<"
    case lessThanOrEqualTo = "<="
    case greaterThan = ">"
    case greaterThanOrEqualTo = "$>="
    case notEqualTo = "$!=="
    case equalTo = "==="
    
}

extension NSComparisonPredicate {
    
    var mongoDBOperator: MongoDBOperator? {
        switch predicateOperatorType {
        case .lessThan:
            return .lessThan
        case .lessThanOrEqualTo:
            return .lessThanOrEqualTo
        case .greaterThan:
            return .greaterThan
        case .greaterThanOrEqualTo:
            return .greaterThanOrEqualTo
        case .equalTo:
            return .equalTo
        case .notEqualTo:
            return .notEqualTo
        case .in:
            return .in
        case .matches:
            return .matches
        default:
            return nil
        }
    }
    
    var mongoDBJavaScriptOperator: MongoDBJavaScriptOperator? {
        switch predicateOperatorType {
        case .lessThan:
            return .lessThan
        case .lessThanOrEqualTo:
            return .lessThanOrEqualTo
        case .greaterThan:
            return .greaterThan
        case .greaterThanOrEqualTo:
            return .greaterThanOrEqualTo
        case .equalTo:
            return .equalTo
        case .notEqualTo:
            return .notEqualTo
        default:
            return nil
        }
    }
    
}

extension NSCompoundPredicate {
    
    var mongoDBOperator: MongoDBOperator {
        switch compoundPredicateType {
        case .not: return .not
        case .and: return .and
        case .or: return .or
        }
    }
    
}

extension NSPredicate {
    
    public var mongoDBQuery: [String : Any]? {
        return mongoDBQuery()
    }
    
    public func mongoDBQuery(optimize: Bool = true) -> [String : Any]? {
        var result: [String : Any]? = nil
        if let predicate = self as? NSComparisonPredicate {
            result = transform(comparisonPredicate: predicate)
        } else if let predicate = self as? NSCompoundPredicate {
            result = transform(compoundPredicate: predicate)
            if optimize,
                let _result = result,
                _result.count == 1,
                let (key, _value) = _result.first,
                key == MongoDBOperator.and.rawValue,
                let value = _value as? [[String : Any]],
                let sequence = Optional(value.filter({ $0.count == 1 }).compactMap({ $0.first })),
                value.count == Set(sequence.map{ $0.key }).count
            {
                result = [String : Any](uniqueKeysWithValues: sequence)
            }
        }
        return result
    }
    
    private func transform(comparisonPredicate predicate: NSComparisonPredicate) -> [String : Any]? {
        var result: [String : Any]? = nil
        if predicate.leftExpression.expressionType == .function ||
            predicate.rightExpression.expressionType == .function
        {
            result = transform(functionPredicate: predicate)
        } else {
            if var `operator` = predicate.mongoDBOperator {
                result = transform(expressionsInComparisonPredicate: predicate, operator: &`operator`)
            } else if let replacementPredicate = replacementPredicate(forComparisonPredicate: predicate) {
                result = replacementPredicate.mongoDBQuery
            }
        }
        return result
    }
    
    private func transform(predicates: [NSPredicate], operator: MongoDBOperator) -> [String : Any]? {
        var subPredicates = [[String : Any]]()
        for predicate in predicates {
            if let subResult = predicate.mongoDBQuery {
                subPredicates.append(subResult)
            }
        }
        return [`operator`.rawValue : subPredicates]
    }
    
    private func transform(compoundPredicate predicate: NSCompoundPredicate) -> [String : Any]? {
        return transform(
            predicates: predicate.subpredicates as! [NSPredicate],
            operator: predicate.mongoDBOperator
        )
    }
    
    private func replacementPredicate(forComparisonPredicate predicate: NSComparisonPredicate) -> NSPredicate? {
        switch predicate.predicateOperatorType {
        case .between:
            return replacementPredicate(forBetweenPredicate: predicate)
        case .beginsWith:
            return replacementPredicate(forBeginsWithPredicate: predicate)
        case .contains:
            return replacementPredicate(forContainsPredicate: predicate)
        case .endsWith:
            return replacementPredicate(forEndsWithPredicate: predicate)
        case .like:
            return replacementPredicate(forLikePredicate: predicate)
        default:
            return nil
        }
    }
    
    private func replacementPredicate(forBeginsWithPredicate predicate: NSComparisonPredicate) -> NSPredicate? {
        if let constantValue = predicate.rightExpression.constantValue {
            let beginsWithRegex = "^\(constantValue)"
            return replacementPredicate(
                forComparisonPredicate: predicate,
                withRegexString: beginsWithRegex
            )
        }
        return nil
    }
    
    private func replacementPredicate(forEndsWithPredicate predicate: NSComparisonPredicate) -> NSPredicate? {
        if let constantValue = predicate.rightExpression.constantValue {
            let endsWithRegex = ".*\(constantValue)"
            return replacementPredicate(
                forComparisonPredicate: predicate,
                withRegexString: endsWithRegex
            )
        }
        return nil
    }
    
    private func replacementPredicate(forContainsPredicate predicate: NSComparisonPredicate) -> NSPredicate? {
        if let constantValue = predicate.rightExpression.constantValue {
            let containsRegex = ".*\(constantValue).*"
            return replacementPredicate(
                forComparisonPredicate: predicate,
                withRegexString: containsRegex
            )
        }
        return nil
    }
    
    private func replacementPredicate(forLikePredicate predicate: NSComparisonPredicate) -> NSPredicate? {
        if let constantValue = predicate.rightExpression.constantValue {
            let likeRegex = "/(\(constantValue))/"
            return replacementPredicate(
                forComparisonPredicate: predicate,
                withRegexString: likeRegex
            )
        }
        return nil
    }
    
    private func replacementPredicate(forComparisonPredicate predicate: NSComparisonPredicate, withRegexString regex: String) -> NSPredicate? {
        let newRightExpression = NSExpression(forConstantValue: regex)
        let newPredicate = NSComparisonPredicate(
            leftExpression: predicate.leftExpression,
            rightExpression: newRightExpression,
            modifier: predicate.comparisonPredicateModifier,
            type: .matches,
            options: predicate.options
        )
        return newPredicate
    }
    
    private func replacementPredicate(forBetweenPredicate predicate: NSComparisonPredicate) -> NSPredicate? {
        let rightExpression = predicate.rightExpression
        
        guard let bounds = rightExpression.constantValue as? [Any], bounds.count == 2 else {
            return nil
        }
        let lowerBound = bounds.first
        let upperBound = bounds.last
        
        let lowerBoundExpression = ensureExpression(lowerBound)
        let upperBoundExpression = ensureExpression(upperBound)
        
        var subPredicates = [NSPredicate]()
        
        let leftExpression = predicate.leftExpression
        
        let lowerSubPredicate = NSComparisonPredicate(
            leftExpression: leftExpression,
            rightExpression: lowerBoundExpression,
            modifier: predicate.comparisonPredicateModifier,
            type: .greaterThanOrEqualTo,
            options: predicate.options
        )
        subPredicates.append(lowerSubPredicate)
        
        let upperSubPredicate = NSComparisonPredicate(
            leftExpression: leftExpression,
            rightExpression: upperBoundExpression,
            modifier: predicate.comparisonPredicateModifier,
            type: .lessThanOrEqualTo,
            options: predicate.options
        )
        subPredicates.append(upperSubPredicate)
        
        return NSCompoundPredicate(andPredicateWithSubpredicates: subPredicates)
    }
    
    private func ensureExpression(_ item: Any?) -> NSExpression {
        if let expression = item as? NSExpression {
            return expression
        }
        
        return NSExpression(forConstantValue: item)
    }
    
    private func transform(functionPredicate predicate: NSComparisonPredicate) -> [String : Any]? {
        var result: [String : Any]? = nil
        let predicate = predicateWithJSThisToKeyPaths(inPredicate: predicate)
        if let `operator` = predicate.mongoDBJavaScriptOperator {
            result = ["$where" : "\(predicate.leftExpression) \(`operator`) \(predicate.rightExpression)"]
        }
        return result
    }
    
    private func predicateWithJSThisToKeyPaths(inPredicate predicate: NSComparisonPredicate) -> NSComparisonPredicate {
        let leftExpression = ensureKeyPathExpressionsContainJSThis(inExpression: predicate.leftExpression)
        let rightExpression = ensureKeyPathExpressionsContainJSThis(inExpression: predicate.rightExpression)
        let newPredicate = NSComparisonPredicate(
            leftExpression: leftExpression,
            rightExpression: rightExpression,
            modifier: predicate.comparisonPredicateModifier,
            type: predicate.predicateOperatorType,
            options: predicate.options
        )
        return newPredicate
    }
    
    //MARK: - expression transformation
    
    private func transform(expression: NSExpression, modifyingOperator `operator`: inout MongoDBOperator) -> Any? {
        switch expression.expressionType {
        case .constantValue:
            return transform(
                constant: expression.constantValue,
                modifyingOperator: &`operator`
            )
        case .keyPath:
            return expression.keyPath
        default:
            return nil
        }
    }
    
    private func transform(expressionsInComparisonPredicate predicate: NSComparisonPredicate, operator: inout MongoDBOperator) -> [String : Any]? {
        if let keyPathConstantTuple = predicate.keyPathConstantTuple,
            keyPathConstantTuple.keyPathExpression.keyPath.hasSuffix(".@count")
        {
            var keyPath = keyPathConstantTuple.keyPathExpression.keyPath
            #if swift(>=4.0)
                let countOffset = ".@count".count
            #else
                let countOffset = ".@count".characters.count
            #endif
            keyPath = String(keyPath[...keyPath.index(keyPath.endIndex, offsetBy: -countOffset - 1)])
            let value = transform(constant: keyPathConstantTuple.constantValueExpression.constantValue, modifyingOperator: &`operator`)
            return [keyPath : ["$size" : value]]
        }
        
        let field = transform(expression: predicate.leftExpression, modifyingOperator: &`operator`)
        let param = transform(expression: predicate.rightExpression, modifyingOperator: &`operator`)
        
        switch `operator` {
        case .equalTo:
            return [field as! String : param!]
        default:
            let query = [`operator`.rawValue : param]
            return [field as! String : query]
        }
    }
    
    private func ensureKeyPathExpressionsContainJSThis(inExpression expression: NSExpression) -> NSExpression {
        switch expression.expressionType {
        case .keyPath:
            return NSExpression(forKeyPath: "this.\(expression.keyPath)")
        case .function:
            var newArguments = [NSExpression]()
            if let arguments = expression.arguments {
                for argument in arguments {
                    newArguments.append(ensureKeyPathExpressionsContainJSThis(inExpression: argument))
                }
            }
            return NSExpression(forFunction: expression.function, arguments: newArguments)
        default:
            return expression
        }
    }
    
    //MARK: - Constant Transformation
    
    private func transform(constant: Any?, modifyingOperator `operator`: inout MongoDBOperator) -> Any? {
        
        if constant == nil || constant is NSNull {
            return NSNull()
        } else if constant is String {
            switch `operator` {
            case .in:
                return [constant]
            default:
                return constant
            }
        } else if let date = constant as? Date {
            return date.timeIntervalSince1970
        } else if constant is NSDecimalNumber ||
            constant is NSNumber ||
            constant is NSArray
        {
            return constant
        } else if let set = constant as? NSSet {
            return set.allObjects
        }
#if canImport(MapKit)
        if let shape = constant as? MKShape {
            `operator` = .geoIn
            return transform(geoShape: shape)
        }
#endif
        
        return nil
    }
    
    #if canImport(MapKit)
    private func transform(geoShape: MKShape) -> [String : Any]? {
        if let circle = geoShape as? MKCircle {
            return [
                "$centerSphere" : [
                    [
                        circle.coordinate.longitude,
                        circle.coordinate.latitude
                    ],
                    circle.radius / 6371000.0
                ]
            ]
        } else if let polygon = geoShape as? MKPolygon {
            let pointCount = polygon.pointCount
            var coordinates = [CLLocationCoordinate2D](repeating: CLLocationCoordinate2D(), count: pointCount)
            polygon.getCoordinates(&coordinates, range: NSMakeRange(0, pointCount))
            let coordinatesArray = coordinates.map { [$0.longitude, $0.latitude] }
            return ["$polygon" : coordinatesArray]
        }
        return nil
    }
    #endif
    
}

extension NSComparisonPredicate {
    
    var keyPathConstantTuple: (keyPathExpression: NSExpression, constantValueExpression: NSExpression)? {
        switch leftExpression.expressionType {
        case .keyPath:
            switch rightExpression.expressionType {
            case .constantValue:
                return (keyPathExpression: leftExpression, constantValueExpression: rightExpression)
            default:
                return nil
            }
        case .constantValue:
            switch rightExpression.expressionType {
            case .keyPath:
                return (keyPathExpression: rightExpression, constantValueExpression: leftExpression)
            default:
                return nil
            }
        default:
            return nil
        }
    }
    
}
