//
//  JSONCompositionTests.swift
//
//
//  Created by Antoine Palazzolo on 06/11/15.
//  
//

import Foundation
import XCTest
import FunctionalJSON
import FunctionalBuilder



class JSONCompositionTests : XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    
    func testComplexComposition() {
        let source : [String : Any] = [
            "prop1" : 3,
            "prop2" : ["this","is","madness","!"],
            "prop3" : "http://google.com",
            "prop4" : [
                "prop1" : true,
                "prop2" : "hello",
                "prop3" : [1,2,3,4]
            ],
            "prop5" : [["p1" : 2, "p2" : false],["p1" : 12, "p2" : true],["p1" : 12, "p2" : NSNull()]],
            "prop6" : ["p1" : 2, "p2" : "couocu"],
            "prop7" : NSNull(),
        ]
        
        let json = try! jsonFromAny(source)
        
        let readProp4 = JSONRead(
            JSONPath("prop1").read(Bool.self) <&>
            JSONPath("prop2").read(String.self) <&>
            JSONPath("prop3").read([Int].jsonRead()).map {$0.reduce(0, +)}
        )
        let readProp5 = Array.jsonRead(JSONRead(JSONPath("p1").read(Int.self) <&> JSONPath("p2").read((Bool?).self)))
        
        let finalRead = JSONRead(
            JSONPath("prop1").read(Int.self) <&>
            JSONPath("prop2").read([String].self).map {$0.joined(separator: " ")} <&>
            JSONPath("prop3").read(URL.jsonRead) <&>
            JSONPath("prop4").read(readProp4) <&>
            JSONPath("prop5").read(readProp5) <&>
            JSONPath("prop6").read(JSONPath("p1").read(Int.self) <&> JSONPath("p2").read(String.self))
        )
        
        let ret = try! json.validate(finalRead)
        
        XCTAssertEqual(ret.0, 3)
        XCTAssertEqual(ret.1, "this is madness !")
        XCTAssertEqual(URL(string: "http://google.com")!, ret.2)
        XCTAssertEqual(1+2+3+4, ret.3.2)
        
        
        let otherRead = JSONPath("prop7").read(JSONPath("p1").read(Int.self) <&> JSONPath("p2").read(String.self)).optional
        XCTAssert(try! json.validate(otherRead) == nil)
        
        let readOpt2 = try? json["prop7"].validate(JSONPath("p1").read(Int.self) <&> JSONPath("p2").read(String.self))
        XCTAssert(readOpt2 == nil)
    }
    
    func testCompositionError() {
        let source : [String : Any] = [
            "prop1" : 3,
            "prop2" : ["this" : "is","madness" : "!"],
            "prop3" : "http://google‘ë“{{‘¶.com",
            "prop4" : ["p1" : NSNull()]
        ]
        
        let json = try! jsonFromAny(source)
        
        let subRead = JSONPath("p1").read(String.self)
        let finalRead = JSONRead(
            JSONPath("prop1").read(String.self) <&>
            JSONPath("prop2","madness").read([String].self) <&>
            JSONPath("prop3").read(URL.jsonRead) <&>
            JSONPath("prop3",0,"coucou").read(URL.jsonRead) <&>
            JSONPath("prop4").read(subRead) <&>
            JSONPath("prop4").read(JSONPath("p4").read(String.self)<&>JSONPath("p5").read(String.self))
        )
        
        do {
            let _ = try json.validate(finalRead)
        } catch let x as JSONValidationError  {
            let errors = x.content
            if case JSONReadError.badValueType(let path) = errors[0] {
                XCTAssertEqual(path, JSONPath("prop1"))
            } else {
                XCTFail("should be a bad value error")
            }
            
            if case JSONReadError.badValueType(let path) = errors[1] {
                XCTAssertEqual(path, JSONPath(["prop2","madness"]))
            } else {
                XCTFail("should be a bad value error \(errors[1])")
            }
            
            if case JSONReadError.transformError(let path, underlying: _) = errors[2] {
                XCTAssertEqual(path, JSONPath(["prop3"]))
            } else {
                XCTFail("should be a TransformError error \(errors[2])")
            }
            
            if case JSONReadError.valueNotFound(let path) = errors[3] {
                XCTAssertEqual(path, JSONPath(["prop3",0,"coucou"]))
            } else {
                XCTFail("should be a ValueNotFound error \(errors[3])")
            }
            
            if case JSONReadError.valueNotFound(let path) = errors[4] {
                XCTAssertEqual(path, JSONPath(["prop4","p1"]))
            } else {
                XCTFail("should be a ValueNotFound error \(errors[4])")
            }
            
            if case JSONReadError.valueNotFound(let path) = errors[5] {
                XCTAssertEqual(path, JSONPath(["prop4","p4"]))
            } else {
                XCTFail("should be a ValueNotFound error \(errors[5])")
            }
            if case JSONReadError.valueNotFound(let path) = errors[6] {
                XCTAssertEqual(path, JSONPath(["prop4","p5"]))
            } else {
                XCTFail("should be a ValueNotFound error \(errors[6])")
            }
            
        } catch {
            XCTFail("should be a composition error, \(error)")
        }
    }
    func testArrayError() {
        let json = try! jsonFromAny([["id" : "34233"], ["identifier" : 34233]])
        let read = JSONPath("id").read(Int.self)
        do {
            let _ = try json.validate(Array.jsonRead(read))
        } catch let x as JSONValidationError {
            let errors = x.content
            XCTAssertEqual(x.content.count, 2)
            
            if case JSONReadError.badValueType(let path) = errors[0] {
                XCTAssertEqual(path, JSONPath([0,"id"]))
            } else {
                XCTFail("should be a BadValueType error \(errors[1])")
            }
            
            if case JSONReadError.valueNotFound(let path) = errors[1] {
                XCTAssertEqual(path, JSONPath([1,"id"]))
            } else {
                XCTFail("should be a ValueNotFound error \(errors[1])")
            }
        } catch {
            XCTFail("should be a CompositionError error \(error)")
        }

    }
    
}
