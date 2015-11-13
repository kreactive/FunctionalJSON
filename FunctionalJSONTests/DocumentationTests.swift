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
                JSONPath("name").read(String) <&>
                JSONPath("age").read(Int?) <&>
                JSONPath("transactions").read([Transaction])
            ).map(Person.init)
    }
    struct Transaction : JSONReadable {
        let identifier : Int64
        static let jsonRead = JSONPath("id").read(Int64).map(Transaction.init)
    }
    
    func testUsageDoc() {
        let jsonData : NSData = NSData(contentsOfFile: NSBundle(forClass: self.dynamicType).pathForResource("usageDoc", ofType: "json")!)!

        let json = try! JSONValue(data : jsonData)
        
        let persons : [Person] = try! json["customers"].validate([Person])

        XCTAssertEqual(persons.count,3)
        
    }
    func testValidationDoc() {
        let jsonData : NSData = NSData(contentsOfFile: NSBundle(forClass: self.dynamicType).pathForResource("validationDoc", ofType: "json")!)!
        
        let json = try! JSONValue(data : jsonData)
        
        do {
            let _ = try json.validate(Person)
            XCTFail("should fail")
        } catch {
            print(error)
        }
    }
    
    private enum Error : ErrorType {
        case DateError
    }
    func testReadExample() {
        
        let read : JSONRead<Int> = JSONPath(["customers",0,"age"]).read(Int)
        let readDate : JSONRead<NSDate> = read.map {
            guard let date = NSCalendar.currentCalendar().dateByAddingUnit(.Year,
                value: -$0,
                toDate: NSDate(),
                options: []) else {
                throw Error.DateError
            }
            return date
        }
        
        let optionalRead : JSONRead<NSDate?> = readDate.optional
        let defaultDateRead : JSONRead<NSDate> = readDate.withDefault(NSDate())
        
        let jsonValue = try! jsonFromAny(["customers" : [["name" : "dqs", "age": 28]]])
        
        let date1 = try! jsonValue.validate(optionalRead)
        let date2 = try! jsonValue.validate(defaultDateRead)
        
        XCTAssertNotNil(date1)
        XCTAssertNotNil(date2)

    }
    func testJSONValueExample() {
        
        let jsonSource = ["customers" : [["name" : "dqs", "age": 28]]]
        let jsonData = try! NSJSONSerialization.dataWithJSONObject(jsonSource, options: [])
        let json = try? JSONValue(data: jsonData, options : [.AllowFragments])
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