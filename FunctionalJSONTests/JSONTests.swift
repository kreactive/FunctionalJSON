//
//Tests.swift
//Tests
//
//  Created by Antoine Palazzolo on 05/11/15.
//  
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
        
        static let jsonRead = JSONRead(JSONPath("prop1").read(String.self) <&> JSONPath("prop2").read(Int.self) <&> JSONPath("prop3").read((Int?).self) <&> JSONPath("prop4").read(Bool.self)).map(Foo.init)
    }
    
    func testParseBasic() {
       
        let jsonObject : [String : Any] = ["prop1" : "coucou", "prop2" : 23, "prop3" : NSNull(), "prop4" : true]
        
        let json = try! jsonFromAny(jsonObject)
        
        let foo = try! json.validate(Foo.self)
        XCTAssertEqual(foo.prop1,"coucou")
        XCTAssertEqual(foo.prop2, 23)
        XCTAssertNil(foo.prop3)
        XCTAssertTrue(foo.prop4)

        
    }
    struct Foo2 : JSONReadable {
        let prop1 : Foo
        let prop2 : String
        static let jsonRead = JSONRead(
            JSONPath("prop1").read(Foo.self) <&>
            JSONPath("prop2").read(String.self)
            ).map(Foo2.init)
    }
    func testParseErrorComplexe() {
        let source = [
            "foo" : [
                "foo1" : [
                    "prop1" : ["prop1" : "coucou", "prop2" : 23, "prop3" : NSNull(), "prop4" : true],
                    "prop2" : "coucou"
                ],
                "foo2" : [
                    "prop2" : "coucou"
                ]
            ]
        ]
        let json = try! jsonFromAny(source)
        let read = JSONPath("foo").read(JSONPath("foo1").read(Foo2.self) <&> JSONPath("foo2").read(Foo2.self))
        do {
            let _ = try json.validate(read)
            XCTFail("should fail")
        } catch {}
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
        XCTAssertEqual(try! json.validate(JSONPath(1).read(Int.self)), 2)
        XCTAssertEqual(try! json.validate(JSONPath([3,0]).read(Int.self)), 4)
        XCTAssertEqual(try! json.validate(JSONPath([3,1,1]).read(Int.self)), 6)
        XCTAssertEqual(try! json.validate(JSONPath([3,2]).read(Int.self)), 7)
        XCTAssertEqual(try! json.validate((JSONPath(3)+2).read(Int.self)), 7)

        XCTAssertEqual(try! json.validate((JSONPath([3,1,2])+3).read((Int?).self)), nil)
        XCTAssertEqual(try! json[[3,1,2]].validate((Int?).self), nil)

    }
    func testObjectNavigation() {
        let json = try! jsonFromAny(["1" : 1,"2" : ["4" : ["5" : 6], "7" : 8]])
        XCTAssertEqual(try! json.validate(JSONPath("1").read(Int.self)), 1)
        XCTAssertEqual(try! json.validate(JSONPath(["2","7",]).read(Int.self)), 8)
        XCTAssertEqual(try! json.validate((JSONPath(["2","4"])+"5").read(Int.self)), 6)
        
        XCTAssertEqual(try! json.validate((JSONPath(["2","4","Nop"])+"nopnop").read((Int?).self)), nil)
        XCTAssertEqual(try! json.validate(JSONPath(["2","nop","Nop"]).read((Int?).self)), nil)

        XCTAssertEqual(try! json[["2","nop","Nop"]].validate((Int?).self), nil)
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
        
        XCTAssertEqual(try! json.validate(JSONPath(["1",1]).read(Int.self)), 2)
        XCTAssertEqual(try! json.validate(JSONPath(["1",3,"6"]).read(Int.self)), 7)
        XCTAssertEqual(try! json.validate(JSONPath(["8",0,"10"]).read(Int.self)), 11)
        XCTAssertEqual(try! json.validate(JSONPath(0).read((Int?).self)), nil)

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
    func testPathComponentBuild() {
        let path1 : JSONPath = [JSONPathComponent("1"),JSONPathComponent(0)]
        XCTAssertEqual(path1, JSONPath(["1",0]))
    }
    
    func testPathDescription() {
        let path1 : JSONPath = "part1"+"part2"+"part3"
        XCTAssertNotNil(path1.description)
        
        let path2 : JSONPath = "part1"+3+"part3"
        XCTAssertNotNil(path2.description)
        
        let path3 : JSONPath = "part12"+"part2"+0+"part3"
        XCTAssertNotNil(path3.description)
        
    }
    func testToOpt() {
        let json = try! jsonFromAny(["1" : 1, "2": [1,2,3]])
        
        XCTAssertNil(try! json["1"].validate((String?).self))
        XCTAssertNotNil(try! json["1"].validate((Int?).self))
        
        XCTAssertNil(try! json.validate(JSONPath("1").read((String?).self)))
        XCTAssertNotNil(try! json.validate(JSONPath("1").read((Int?).self)))

        XCTAssertNil(try! json["1"].validate(([String]?).self))
        XCTAssertNotNil(try! json["2"].validate(([Int]?).self))

        XCTAssertNil(try! json.validate(JSONPath("1").read(([String]?).self)))
        XCTAssertNotNil(try! json.validate(JSONPath("2").read(([Int]?).self)))
    }
    func testReadJSONValue() {
        let json = try! jsonFromAny(["1" : 1, "2": [1,2,3]])
        let value = try! json.validate(JSONPath("2").read())
        XCTAssertTrue(value.underlying is Array<Int>)
    }
    func testReadWithDefault() {
        let json = try! jsonFromAny(["1" : 1, "2": [1,2,3]])
        
        let value = try! json.validate(JSONPath("2").read(Int.self).withDefault(4))
        XCTAssertEqual(value, 4)
    }
    
    func testDebugDescription() {
        let json1 = try! jsonFromAny([1])
        do {
            let _ = try json1[0].validate(String.self)
        } catch let error as JSONValidationError {
            let _ = error.debugDescription
        } catch {
            XCTFail("")
        }
        
        do {
            let _ = try json1.validate(JSONPath("0").read(String.self) <&> JSONPath("2").read(JSONPath("0").read(Int.self) <&> JSONPath("0").read(Int.self)))
        } catch let error as JSONValidationError {
            let _ = error.debugDescription
        } catch {
            XCTFail("")
        }
        
        do {
            let _ = try json1.validate(JSONPath(0).read(Int.self).map({_ -> String in throw NSError(domain: "", code: 0, userInfo: nil)}))
        } catch let error as JSONValidationError {
            let _ = error.debugDescription
        } catch {
            XCTFail("")
        }
    }
    
    func testPathOnJSONValues() {
        let underlyingDict : [String : Any] = [
            "key1" : "blabla",
            "key2" : 1,
            "key3" : "dqsd",
            "key4" : true,
            "key5" : 1.4
        ]
        let jsonValueDic = JSONValue(underlying: underlyingDict, path: JSONPath())
        XCTAssertEqual(
            Set(["key1","key2","key3","key4","key5"].map(JSONPathComponent.init(_:))),
            Set(jsonValueDic.subPathComponents)
        )
        
        
        let undelyingArray : [Any] = ["1234", 1.2, 1, "", true]
        let jsonValueArray = JSONValue(underlying: undelyingArray, path: JSONPath())
        XCTAssertEqual(
            Set([0,1,2,3,4].map(JSONPathComponent.init(_:))),
            Set(jsonValueArray.subPathComponents)
        )

        let jsonValueNil = JSONValue(underlying: nil, path: JSONPath())
        XCTAssertTrue(jsonValueNil.subPathComponents.isEmpty)
    }
}
