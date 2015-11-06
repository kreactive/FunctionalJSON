//
//  JSONCompositionTests.swift
//
//
//  Created by Antoine Palazzolo on 06/11/15.
//  
//

import Foundation
import XCTest
@testable import FunctionalJSON
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
        let source = [
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
            JSONPath("prop1").read(Bool) <&>
            JSONPath("prop2").read(String) <&>
            JSONPath("prop3").read(Array.jsonRead(Int)).map {$0.reduce(0, combine: +)}
        )
        let readProp5 = Array.jsonRead(JSONRead(JSONPath("p1").read(Int) <&> JSONPath("p2").readOpt(Bool)))
        
        let finalRead = JSONRead(
            JSONPath("prop1").read(Int) <&>
            JSONPath("prop2").read(Array.jsonRead(String)).map {$0.joinWithSeparator(" ")} <&>
            JSONPath("prop3").read(NSURL.jsonRead) <&>
            JSONPath("prop4").read(readProp4) <&>
            JSONPath("prop5").read(readProp5) <&>
            JSONPath("prop6").read(JSONPath("p1").read(Int) <&> JSONPath("p2").read(String))
        )
        
        let ret = try! json.validate(finalRead)
        
        XCTAssertEqual(ret.0, 3)
        XCTAssertEqual(ret.1, "this is madness !")
        XCTAssertEqual(NSURL(string: "http://google.com")!, ret.2)
        XCTAssertEqual(1+2+3+4, ret.3.2)
        
        
        let otherRead = JSONPath("prop7").readOpt(JSONPath("p1").read(Int) <&> JSONPath("p2").read(String))
        XCTAssert(try! json.validate(otherRead) == nil)
        
        let readOpt = json["prop7"].validateOpt(JSONPath("p1").read(Int) <&> JSONPath("p2").read(String))
        XCTAssert(readOpt == nil)
        
        let readOpt2 = try? json["prop7"].validate(JSONPath("p1").read(Int) <&> JSONPath("p2").read(String))
        XCTAssert(readOpt2 == nil)

    }
}