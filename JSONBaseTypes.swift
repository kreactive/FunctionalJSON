//
//  JSONBase.swift
//  AKAds
//
//  Created by Antoine Palazzolo on 20/10/15.
//  Copyright © 2015 Kreactive. All rights reserved.
//

import Foundation

private extension JSONValue {
    func to<U>(_ : U.Type) throws -> U {
        guard let underlying = self.underlying else {throw JSONReadError.ValueNotFound(self.path)}
        guard let ret = underlying as? U else {throw JSONReadError.BadValueType(self.path)}
        return ret
    }
}
private extension NSNumber {
    static let jsonRead = JSONRead<NSNumber> {
        return try $0.to(NSNumber)
    }
}
extension Int : JSONReadable {
    public static let jsonRead = NSNumber.jsonRead.map {$0.integerValue}
}
extension UInt : JSONReadable {
    public static let jsonRead = NSNumber.jsonRead.map {$0.unsignedIntegerValue}
}
extension Bool : JSONReadable {
    public static let jsonRead = NSNumber.jsonRead.map {$0.boolValue}
}
extension Float : JSONReadable {
    public static let jsonRead = NSNumber.jsonRead.map {$0.floatValue}
}
extension Double : JSONReadable {
    public static let jsonRead = NSNumber.jsonRead.map {$0.doubleValue}
}
extension String : JSONReadable {
    public static let jsonRead = JSONRead<String> {try $0.to(String)}
}

public extension Array {
    private static func read() -> JSONRead<[JSONValue]> {
        return JSONRead<[JSONValue]> { v in
            guard let underlying = v.underlying else {throw JSONReadError.ValueNotFound(v.path)}
            guard let arrayValue = underlying as? Array<AnyObject> else {throw JSONReadError.BadValueType(v.path)}
            let ret = arrayValue.enumerate().map {JSONValue(underlying: $0.1, path: v.path+$0.0)}
            return ret
        }

    }
    public static func read<Element>(rds : JSONRead<Element>) -> JSONRead<[Element]> {
        return self.read().map {try $0.map(rds.read)}
    }
    public static func readOpt<Element>(rds : JSONRead<Element>) -> JSONRead<[Element]> {
        return self.read().map { $0.flatMap {try? rds.read($0)}}
    }
}

