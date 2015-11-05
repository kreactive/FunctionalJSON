//
//  TestUtils.swift
//  FunctionalJSON
//
//  Created by Antoine Palazzolo on 05/11/15.
//  Copyright © 2015 Kreactive. All rights reserved.
//

import Foundation
@testable import FunctionalJSON

func jsonFromAny(any : AnyObject) throws -> JSONValue {
    let val : NSDictionary = ["val" : any]
    return try JSONValue(data: NSJSONSerialization.dataWithJSONObject(val,options: [])).elementAtPath("val")
}
func jsonFromAny(any : Dictionary<String,AnyObject>) throws -> JSONValue {
    return try JSONValue(data: NSJSONSerialization.dataWithJSONObject(any,options: []))
}
func jsonFromAny(any : Array<AnyObject>) throws -> JSONValue {
    return try JSONValue(data: NSJSONSerialization.dataWithJSONObject(any,options: []))
}
