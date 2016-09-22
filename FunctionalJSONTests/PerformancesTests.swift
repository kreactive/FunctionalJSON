//
//  PerformancesTests.swift
//  FunctionalJSON
//
//  Created by Antoine Palazzolo on 06/11/15.
//  Copyright © 2015 Kreactive. All rights reserved.
//

import Foundation
import XCTest
import FunctionalJSON
import FunctionalBuilder




class PerformanceTests : XCTestCase {
    
    struct Foo : JSONReadable {
        let prop1 : String
        let prop2 : Int
        let prop3 : Int?
        let prop4 : Bool
        
        static let jsonRead = JSONRead(JSONPath("prop1").read(String.self) <&> JSONPath("prop2").read(Int.self) <&> JSONPath("prop3").read((Int?).self) <&> JSONPath("prop4").read(Bool.self)).map(Foo.init)
    }
    
    let source : [Any] = {
        let source : [Any] = [
            [
                "prop1" : "coucou",
                "prop2" : 2,
                "prop3" : 4,
                "prop4" : true
            ],
            [
                "prop1" : "coucou",
                "prop2" : 2,
                "prop3" : NSNull(),
                "prop4" : true
            ]
        ]
        
        var final = [Any]()
        for _ in 0...200 {
            final.append(contentsOf: source)
        }
        return final
    }()
    
    func testReadPerf() {
        let json = try! jsonFromAny(self.source)
        self.measure {
            let _ = try! json.validate([Foo].jsonRead())
        }
    }
    func testReadPerfManual() {
        let jsonData = try! JSONSerialization.data(withJSONObject: self.source, options: [])
        let json = try! JSONSerialization.jsonObject(with: jsonData, options: [])
        self.measure {
            let _ = try! self.manualParse(json)
        }
    }
    
    
    private enum MyError : Error {
        case err
    }
    func manualParse(_ json : Any) throws -> [Foo] {
        guard let array = json as? Array<Dictionary<String,AnyObject>> else { throw MyError.err }
        
        var foos = [Foo]()
        for object in array {
            let p1 = object["prop1"] as? String
            let p2 = object["prop2"] as? NSNumber
            let p3 = object["prop2"] as? NSNumber
            let p4 = object["prop2"] as? NSNumber
            if let p1 = p1, let p2 = p2, let p4 = p4 {
                let foo = Foo(prop1: p1, prop2: p2.intValue, prop3: p3?.intValue, prop4: p4.boolValue)
                foos.append(foo)
            } else {
                throw MyError.err
            }
        }
        return foos

    }
    
}
