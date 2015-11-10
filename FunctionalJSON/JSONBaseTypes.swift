//
//  JSONBase.swift
//  AKAds
//
//  Created by Antoine Palazzolo on 20/10/15.
//  
//

import Foundation

private extension JSONValue {
    func to<U>(_ : U.Type) throws -> U {
        guard let underlying = self.underlying else { throw JSONReadError.ValueNotFound(self.path) }
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
extension Int8 : JSONReadable {
    public static let jsonRead = NSNumber.jsonRead.map {$0.charValue}
}
extension Int16 : JSONReadable {
    public static let jsonRead = NSNumber.jsonRead.map {$0.shortValue}
}
extension Int32 : JSONReadable {
    public static let jsonRead = NSNumber.jsonRead.map {$0.intValue}
}
extension Int64 : JSONReadable {
    public static let jsonRead = NSNumber.jsonRead.map {$0.longLongValue}
}
extension UInt : JSONReadable {
    public static let jsonRead = NSNumber.jsonRead.map {$0.unsignedIntegerValue}
}
extension UInt8 : JSONReadable {
    public static let jsonRead = NSNumber.jsonRead.map {$0.unsignedCharValue}
}
extension UInt16 : JSONReadable {
    public static let jsonRead = NSNumber.jsonRead.map {$0.unsignedShortValue}
}
extension UInt32 : JSONReadable {
    public static let jsonRead = NSNumber.jsonRead.map {$0.unsignedIntValue}
}
extension UInt64 : JSONReadable {
    public static let jsonRead = NSNumber.jsonRead.map {$0.unsignedLongLongValue}
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
    internal static func jsonReadValues() -> JSONRead<[JSONValue]> {
        return JSONRead<[JSONValue]> { v in
            guard let underlying = v.underlying else {throw JSONReadError.ValueNotFound(v.path)}
            guard let arrayValue = underlying as? Array<AnyObject> else {throw JSONReadError.BadValueType(v.path)}
            let ret = arrayValue.enumerate().map {JSONValue(underlying: $0.1, path: v.path+$0.0)}
            return ret
        }
    }
    public static func jsonRead(rds : JSONRead<Element>) -> JSONRead<[Element]> {
        return self.jsonReadValues().map {try $0.map(rds.read)}
    }
    public static func jsonReadOpt(rds : JSONRead<Element>) -> JSONRead<[Element?]> {
        return self.jsonReadValues().map { $0.map {try? rds.read($0)}}
    }
    public static func jsonReadOptFlat(rds : JSONRead<Element>) -> JSONRead<[Element]> {
        return self.jsonReadValues().map { $0.flatMap {try? rds.read($0)}}
    }
}
public extension Array where Element : JSONReadable {
    public static func jsonRead() -> JSONRead<[Element]> {
        return self.jsonRead(Element.jsonRead)
    }
    public static func jsonReadOpt() -> JSONRead<[Element?]> {
        return self.jsonReadOpt(Element.jsonRead)
    }
    public static func jsonReadOptFlat() -> JSONRead<[Element]> {
        return self.jsonReadOptFlat(Element.jsonRead)
    }
}

public extension JSONValue {
    public func validate<T : JSONReadable>(v : [T].Type) throws -> [T] {
        return try self.validate(v.jsonRead())
    }
    public func validateOpt<T : JSONReadable>(v : [T].Type) -> [T]? {
        return self.validateOpt(v.jsonRead())
    }
}
public extension JSONPath {
    public func read<T: JSONReadable>(v : [T].Type) -> JSONRead<[T]> {
        return self.read(v.jsonRead())
    }
    public func readOpt<T: JSONReadable>(v : [T].Type) -> JSONRead<[T]?> {
        return self.readOpt(v.jsonRead())
    }
}

