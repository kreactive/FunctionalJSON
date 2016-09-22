//
//  DocumentationTests.swift
//
//  Created by Antoine Palazzolo on 12/11/15.
//

import XCTest
import Foundation

@testable import FunctionalJSON
import FunctionalBuilder


class DocumentationTests : XCTestCase {
    
    struct Person : JSONReadable {
        let name : String
        let age : Int?
        let transactions : [Transaction]
        
        static let jsonRead = JSONRead(
                JSONPath("name").read(String.self) <&>
                JSONPath("age").read((Int?).self) <&>
                JSONPath("transactions").read([Transaction].self)
            ).map(Person.init)
    }
    struct Transaction : JSONReadable {
        let identifier : Int64
        static let jsonRead = JSONPath("id").read(Int64.self).map(Transaction.init)
    }
    
    func testUsageDoc() {
        let jsonData : Data = try! Data(contentsOf: URL(fileURLWithPath: Bundle(for: type(of: self)).path(forResource: "usageDoc", ofType: "json")!))

        let json = try! JSONValue(data : jsonData)
        
        let persons : [Person] = try! json["customers"].validate([Person].self)

        XCTAssertEqual(persons.count,3)
        
    }
    func testValidationDoc() {
        let jsonData : Data = try! Data(contentsOf: URL(fileURLWithPath: Bundle(for: type(of: self)).path(forResource: "validationDoc", ofType: "json")!))
        
        let json = try! JSONValue(data : jsonData)
        
        do {
            let _ = try json.validate(Person.self)
            XCTFail("should fail")
        } catch {
            print(error)
        }
    }
    
    private enum MyError : Error {
        case dateError
    }
    func testReadExample() {
        
        let read : JSONRead<Int> = JSONPath(["customers",0,"age"]).read(Int.self)
        let readDate : JSONRead<Date> = read.map {
            var dateComponents = DateComponents()
            dateComponents.year = -$0
            
            guard let date = Calendar.current.date(byAdding: dateComponents, to: Date()) else {
                throw MyError.dateError
            }
            return date
        }
        
        let optionalRead : JSONRead<Date?> = readDate.optional
        let defaultDateRead : JSONRead<Date> = readDate.withDefault(Date())
        
        let jsonValue = try! jsonFromAny(["customers" : [["name" : "dqs", "age": 28]]])
        
        let date1 = try! jsonValue.validate(optionalRead)
        let date2 = try! jsonValue.validate(defaultDateRead)
        
        XCTAssertNotNil(date1)
        XCTAssertNotNil(date2)

    }
    func testJSONValueExample() {
        
        let jsonSource = ["customers" : [["name" : "dqs", "age": 28]]]
        let jsonData = try! JSONSerialization.data(withJSONObject: jsonSource, options: [])
        let json = try? JSONValue(data: jsonData, options : [.allowFragments])
        XCTAssertNotNil(json)
        
    }
    func testJSONValueNavigationExample() {
        let json = try! jsonFromAny(["customers" : [["name" : "dqs", "age": 28]]])
        
        let jsonElement1 = json["customers"][0]
        let jsonElement2 = json["customers",0]
        let jsonElement3 = json[JSONPath(["customers",0])]
        XCTAssertEqual(jsonElement1.path, jsonElement2.path)
        XCTAssertEqual(jsonElement3.path, jsonElement2.path)

        let isNull : Bool = json["customers",1992002].isNull
        XCTAssertTrue(isNull)
        
        let isEmpty : Bool = json["customers"].isEmpty
        XCTAssertFalse(isEmpty)

    }
}
