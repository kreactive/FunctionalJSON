//
//  PerformancesTests.swift
//  FunctionalJSON
//
//  Created by Antoine Palazzolo on 06/11/15.
//  Copyright © 2015 Kreactive. All rights reserved.
//

import Foundation
import XCTest
@testable import FunctionalJSON
import FunctionalBuilder




class PerformanceTests : XCTestCase {
    
    struct Foo : JSONReadable {
        let prop1 : String
        let prop2 : Int
        let prop3 : Int?
        let prop4 : Bool
        
        static let jsonRead = JSONRead(JSONPath("prop1").read(String) <&> JSONPath("prop2").read(Int) <&> JSONPath("prop3").readOpt(Int) <&> JSONPath("prop4").read(Bool)).map(Foo.init)
    }
    
    let source : [AnyObject] = {
        let source = [
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
        ] as Array<AnyObject>
        
        var final = Array<AnyObject>()
        for _ in 0...200 {
            final.appendContentsOf(source)
        }
        return final
    }()
    
    func testReadPerf() {
        let json = try! jsonFromAny(self.source)
        self.measureBlock {
            try! json.validate(Array.jsonRead(Foo))
        }
    }
    func testReadPerfManual() {
        let jsonData = try! NSJSONSerialization.dataWithJSONObject(self.source, options: [])
        let json = try! NSJSONSerialization.JSONObjectWithData(jsonData, options: [])
        self.measureBlock {
            try! self.manualParse(json)
        }
    }
    
    
    private enum Error : ErrorType {
        case Err
    }
    func manualParse(json : AnyObject) throws -> [Foo] {
        guard let array = json as? Array<Dictionary<String,AnyObject>> else { throw Error.Err }
        
        var foos = [Foo]()
        for object in array {
            let p1 = object["prop1"] as? String
            let p2 = object["prop2"] as? NSNumber
            let p3 = object["prop2"] as? NSNumber
            let p4 = object["prop2"] as? NSNumber
            if let p1 = p1, p2 = p2, p4 = p4 {
                let foo = Foo(prop1: p1, prop2: p2.integerValue, prop3: p3?.integerValue, prop4: p4.boolValue)
                foos.append(foo)
            } else {
                throw Error.Err
            }
        }
        return foos

    }
    
}