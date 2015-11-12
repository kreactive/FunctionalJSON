//
//  DocumentationTests.swift
//
//  Created by Antoine Palazzolo on 12/11/15.
//

import XCTest
import Foundation

import FunctionalJSON
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
}