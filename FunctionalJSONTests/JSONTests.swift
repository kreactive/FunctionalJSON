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
    
    func testEmpty() {
        let emptyJSONObject = try! jsonFromAny(NSDictionary())
        XCTAssert(emptyJSONObject.isEmpty)
        let notEmptyJSONObject = try! jsonFromAny(["v" : "coucou"])
        XCTAssertFalse(notEmptyJSONObject.isEmpty)
        
        let emptyJSONArray = try! jsonFromAny(NSArray())
        XCTAssert(emptyJSONArray.isEmpty)
        let notEmptyJSONArray = try! jsonFromAny(["coucou"])
        XCTAssertFalse(notEmptyJSONArray.isEmpty)
        
        let nullJSON = try! jsonFromAny(NSArray())[0]
        XCTAssert(nullJSON.isEmpty)
    }
    func testArrayNavigation() {
        let json = try! jsonFromAny([1,2,3,[4,[5,6],7,8]])
        XCTAssertEqual(try! json.validate(JSONPath(1).read(Int)), 2)
        XCTAssertEqual(try! json.validate(JSONPath([3,0]).read(Int)), 4)
        XCTAssertEqual(try! json.validate(JSONPath([3,1,1]).read(Int)), 6)
        XCTAssertEqual(try! json.validate(JSONPath([3,2]).read(Int)), 7)
        XCTAssertEqual(try! json.validate((JSONPath(3)+2).read(Int)), 7)

        XCTAssertEqual(try! json.validate((JSONPath([3,1,2])+3).readOpt(Int)), nil)
        XCTAssertEqual(json[[3,1,2]].validateOpt(Int), nil)

    }
    func testObjectNavigation() {
        let json = try! jsonFromAny(["1" : 1,"2" : ["4" : ["5" : 6], "7" : 8]])
        XCTAssertEqual(try! json.validate(JSONPath("1").read(Int)), 1)
        XCTAssertEqual(try! json.validate(JSONPath(["2","7",]).read(Int)), 8)
        XCTAssertEqual(try! json.validate((JSONPath(["2","4"])+"5").read(Int)), 6)
        
        XCTAssertEqual(try! json.validate((JSONPath(["2","4","Nop"])+"nopnop").readOpt(Int)), nil)
        XCTAssertEqual(try! json.validate(JSONPath(["2","nop","Nop"]).readOpt(Int)), nil)

        XCTAssertEqual(json[["2","nop","Nop"]].validateOpt(Int), nil)
    }
    func testMixedNavigation() {
        let json = try! jsonFromAny([
            "1" : [
                1,
                2,
                3,
                ["6" : 7]
            ],
            "8" : [
                    ["10" : 11],13
                ]
            ])
        
        XCTAssertEqual(try! json.validate(JSONPath(["1",1]).read(Int)), 2)
        XCTAssertEqual(try! json.validate(JSONPath(["1",3,"6"]).read(Int)), 7)
        XCTAssertEqual(try! json.validate(JSONPath(["8",0,"10"]).read(Int)), 11)
        XCTAssertEqual(try! json.validate(JSONPath(0).readOpt(Int)), nil)

    }
    func testPathBuild() {
        let path1 : JSONPath = "part1"+"part2"
        XCTAssertEqual(path1, JSONPath(["part1","part2"]))
        
        let path2 : JSONPath = "part1"+"part2"+0
        XCTAssertEqual(path2, JSONPath(["part1","part2",0]))
        
        let path3 : JSONPath = "part1"+"part2"+0+"part3"
        XCTAssertEqual(path3, JSONPath(["part1","part2",0,"part3"]))
        
        let path4 : JSONPath = 1+2+0+4
        XCTAssertEqual(path4, JSONPath([1,2,0,4]))
        
    }
    func testPathComparison() {
        let path1 : JSONPath = "part1"+"part2"+"part3"
        XCTAssertEqual(path1, path1)
        
        let path2 : JSONPath = "part1"+3+"part3"
        XCTAssertEqual(path2, path2)
        
        let path3 : JSONPath = "part12"+"part2"+0+"part3"
        XCTAssertEqual(path3, path3)
        
        let path4 : JSONPath = 1+2+0+4
        XCTAssertEqual(path4, path4)
        
        XCTAssertEqual(JSONPath(), JSONPath())

        
        XCTAssertNotEqual(path1, path2)
        XCTAssertNotEqual(path1, path3)
        XCTAssertNotEqual(path2, path3)
    }
    func testPathDescription() {
        let path1 : JSONPath = "part1"+"part2"+"part3"
        XCTAssertNotNil(path1.description)
        
        let path2 : JSONPath = "part1"+3+"part3"
        XCTAssertNotNil(path2.description)
        
        let path3 : JSONPath = "part12"+"part2"+0+"part3"
        XCTAssertNotNil(path3.description)
        
    }
}
