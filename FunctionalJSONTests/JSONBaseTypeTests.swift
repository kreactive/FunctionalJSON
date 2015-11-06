
//
//  Created by Antoine Palazzolo on 05/11/15.
//  Copyright © 2015 Kreactive. All rights reserved.
//

import XCTest
@testable import FunctionalJSON
import FunctionalBuilder



private func optionalEqual<T : Equatable>(lhs : T?,_ rhs : T?) -> Bool {
    switch (lhs,rhs) {
    case (.None,.None) :
        return true
    case (.Some(let v1),.Some(let v2)) where v1 == v2 :
        return true
    default :
        return false
    }
}
private func optArrayEqual<T : Equatable>(lhs : [T?], _ rhs : [T?]) -> Bool {
    if lhs.count == rhs.count {
        for (i,v) in lhs.enumerate() {
            if !optionalEqual(v, rhs[i]) {
                return false
            }
        }
        return true
    }
    return false
}

class JSONBaseTypeTest: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    
    func testBaseTypes() {
        XCTAssertEqual(try! jsonFromAny(3).validate(Int),3)
        XCTAssertEqual(try! jsonFromAny(3).validate(Int8),3)
        XCTAssertEqual(try! jsonFromAny(3).validate(Int16),3)
        XCTAssertEqual(try! jsonFromAny(3).validate(Int32),3)
        XCTAssertEqual(try! jsonFromAny(3).validate(Int64),3)
        
        XCTAssertEqual(try! jsonFromAny(3).validate(UInt),3)
        XCTAssertEqual(try! jsonFromAny(3).validate(UInt8),3)
        XCTAssertEqual(try! jsonFromAny(3).validate(UInt16),3)
        XCTAssertEqual(try! jsonFromAny(3).validate(UInt32),3)
        XCTAssertEqual(try! jsonFromAny(3).validate(UInt64),3)
        
        XCTAssertEqual(try! jsonFromAny(true).validate(Bool),true)
        XCTAssertEqual(try! jsonFromAny(3.0).validate(Float),3.0)
        XCTAssertEqual(try! jsonFromAny(3.0).validate(Double),3)
        XCTAssertEqual(try! jsonFromAny("coucou").validate(String),"coucou")
        
        XCTAssertEqual(try! jsonFromAny(["coucou","coucou2"]).validate(Array.jsonRead(String)), ["coucou","coucou2"])
    }
    func testArrayRead() {
        let source = ["string1","string2","string3"]
        let uniformJSON = try! jsonFromAny(source)
        let result = try! uniformJSON.validate(Array.jsonRead(String))
        XCTAssertGreaterThan(result.count, 0)
        XCTAssertEqual(result.count, source.count)
        XCTAssertEqual(result, ["string1","string2","string3"])
    }
    func testArrayReadPath() {
        let source = ["string1","string2",43,true,"string3"]
        let json = try! jsonFromAny(source)
        let read = JSONRead(
            JSONPath(0).read(String) <&>
                JSONPath(1).read(String) <&>
                JSONPath(2).read(Int) <&>
                JSONPath(3).read(Bool) <&>
                JSONPath(4).read(String)
        )
        let result = try! json.validate(read)
        XCTAssertEqual(result.0, source[0])
        XCTAssertEqual(result.1, source[1])
        XCTAssertEqual(result.2, source[2])
        XCTAssertEqual(result.3, source[3])
        XCTAssertEqual(result.4, source[4])
        
    }
    func testArrayOptEqual() {
        let source = ["string1","string2",nil,"string3"] as [String?]
        let compare = ["string1","string2",nil,"string3"] as [String?]
        XCTAssert(optArrayEqual(source, compare))
        
        //bug swift ?
        /*
        let source2 = ["string1","string2","string3"] as [String]
        let compare2 = ["string1","string2","string3"] as [String]
        XCTAssert(optArrayEqual(source2, compare2))
        */
    }
    func testArrayReadOpt() {
        let source = ["string1","string2",43,"string3"]
        let nonUniformJSON = try! jsonFromAny(source)
        let result = try! nonUniformJSON.validate(Array.jsonReadOpt(String))
        XCTAssertGreaterThan(result.count, 0)
        XCTAssertEqual(result.count, source.count)
        
        let compare = ["string1","string2",nil,"string3"] as [(String)?]
        
        XCTAssert(optArrayEqual(result, compare))
    }
    func testArrayReadOptFlat() {
        
        let nonUniformJSON = try! jsonFromAny(["string1","string2",43,"string3"])
        let result = try! nonUniformJSON.validate(Array.jsonReadOptFlat(String))
        let compare = ["string1","string2","string3"]
        XCTAssertGreaterThan(result.count, 0)
        XCTAssertEqual(result, compare)
    }
    func testArrayReadError() {
        
        let json = try! jsonFromAny(["array" : ["string1","string2",43,"string3"]])
        
        do {
            try json.validate(Array.jsonRead(String))
            XCTFail("should fail with bad type error")
        } catch {
            guard case JSONReadError.BadValueType(let path) = error else {
                XCTFail("bad error type, should be bad type, is \(error)")
                return
            }
            XCTAssertEqual(path, JSONPath([]))
        }
        
        do {
            try json.validate(JSONPath(["arrays"]).read(Array.jsonRead(String)))
            XCTFail("should fail with value not found")
        } catch {
            guard case JSONReadError.ValueNotFound(let path) = error else {
                XCTFail("bad error type, should be not found, is \(error)")
                return
            }
            XCTAssertEqual(path, JSONPath(["arrays"]))
        }
    }
}
