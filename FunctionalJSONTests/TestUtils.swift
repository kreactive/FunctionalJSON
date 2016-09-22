//
//  TestUtils.swift
//
//
//  Created by Antoine Palazzolo on 05/11/15.
//  
//

import Foundation
import FunctionalJSON

func jsonFromAny(_ any : [String : Any]) throws -> JSONValue {
    return try JSONValue(data: JSONSerialization.data(withJSONObject: any,options: []))
}
func jsonFromAny(_ any : [Any]) throws -> JSONValue {
    return try JSONValue(data: JSONSerialization.data(withJSONObject: any,options: []))
}
func jsonFromAny(_ any : NSArray) throws -> JSONValue {
    return try JSONValue(data: JSONSerialization.data(withJSONObject: any,options: []))
}
func jsonFromAny(_ any : NSDictionary) throws -> JSONValue {
    return try JSONValue(data: JSONSerialization.data(withJSONObject: any,options: []))
}
