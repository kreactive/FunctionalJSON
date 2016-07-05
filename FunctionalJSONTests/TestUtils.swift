//
//  TestUtils.swift
//
//
//  Created by Antoine Palazzolo on 05/11/15.
//  
//

import Foundation
import FunctionalJSON

func jsonFromAny(any : Dictionary<String,AnyObject>) throws -> JSONValue {
    return try JSONValue(data: NSJSONSerialization.dataWithJSONObject(any,options: []))
}
func jsonFromAny(any : Array<AnyObject>) throws -> JSONValue {
    return try JSONValue(data: NSJSONSerialization.dataWithJSONObject(any,options: []))
}
func jsonFromAny(any : NSArray) throws -> JSONValue {
    return try JSONValue(data: NSJSONSerialization.dataWithJSONObject(any,options: []))
}
func jsonFromAny(any : NSDictionary) throws -> JSONValue {
    return try JSONValue(data: NSJSONSerialization.dataWithJSONObject(any,options: []))
}