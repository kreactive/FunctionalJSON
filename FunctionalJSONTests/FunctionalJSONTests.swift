//
//  FunctionalJSONTests.swift
//  FunctionalJSONTests
//
//  Created by Antoine Palazzolo on 05/11/15.
//  Copyright © 2015 Kreactive. All rights reserved.
//

import XCTest
@testable import FunctionalJSON
import FunctionalBuilder



class FunctionalJSONTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    
    struct Foo : JSONReadable {
        let prop1 : String
        let prop2 : Int
        let prop3 : Int?
        let prop4 : Bool
        
        static let jsonRead = JSONRead(JSONPath("prop1").read(String) <&> JSONPath("prop2").read(Int) <&> JSONPath("prop3").readOpt(Int) <&> JSONPath("prop4").read(Bool)).map(Foo.init)
    }
    
    func testParseBasic() {
       
        let jsonObject = ["prop1" : "coucou", "prop2" : 23, "prop3" : NSNull(), "prop4" : true]
        
        let json = try! jsonFromAny(jsonObject)
        
        let foo = try! json.validate(Foo)
        XCTAssertEqual(foo.prop1,"coucou")
        XCTAssertEqual(foo.prop2, 23)
        XCTAssertNil(foo.prop3)
        XCTAssertTrue(foo.prop4)

        
    }
}
