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
        guard let underlying = self.underlying else { throw JSONReadError.valueNotFound(self.path) }
        guard let ret = underlying as? U else {throw JSONReadError.badValueType(self.path)}
        return ret
    }
}
private extension NSNumber {
    static let jsonRead = JSONRead<NSNumber> {
        return try $0.to(NSNumber.self)
    }
}
extension Int : JSONReadable {
    public static let jsonRead = NSNumber.jsonRead.map {$0.intValue}
}
extension Int8 : JSONReadable {
    public static let jsonRead = NSNumber.jsonRead.map {$0.int8Value}
}
extension Int16 : JSONReadable {
    public static let jsonRead = NSNumber.jsonRead.map {$0.int16Value}
}
extension Int32 : JSONReadable {
    public static let jsonRead = NSNumber.jsonRead.map {$0.int32Value}
}
extension Int64 : JSONReadable {
    public static let jsonRead = NSNumber.jsonRead.map {$0.int64Value}
}
extension UInt : JSONReadable {
    public static let jsonRead = NSNumber.jsonRead.map {$0.uintValue}
}
extension UInt8 : JSONReadable {
    public static let jsonRead = NSNumber.jsonRead.map {$0.uint8Value}
}
extension UInt16 : JSONReadable {
    public static let jsonRead = NSNumber.jsonRead.map {$0.uint16Value}
}
extension UInt32 : JSONReadable {
    public static let jsonRead = NSNumber.jsonRead.map {$0.uint32Value}
}
extension UInt64 : JSONReadable {
    public static let jsonRead = NSNumber.jsonRead.map {$0.uint64Value}
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
    public static let jsonRead = JSONRead<String> {try $0.to(String.self)}
}

public extension Array {
    internal static func jsonReadValues() -> JSONRead<[JSONValue]> {
        return JSONRead<[JSONValue]> { v in
            guard let underlying = v.underlying else {throw JSONReadError.valueNotFound(v.path)}
            guard let arrayValue = underlying as? NSArray else {throw JSONReadError.badValueType(v.path)}
            let ret = arrayValue.enumerated().map {JSONValue(underlying: $0.1, path: v.path+$0.0)}
            return ret
        }
    }
    public static func jsonRead(_ rds : JSONRead<Element>) -> JSONRead<[Element]> {
        return self.jsonReadValues().map {
            var validationError = JSONValidationError()
            var resultAccumulator = [Element]()
            for jsonValue in $0 {
                do {
                    try resultAccumulator.append(rds.read(jsonValue))
                } catch {
                    validationError.append(error)
                }
            }
            if validationError.content.count > 0 {
                throw validationError
            } else {
                return resultAccumulator
            }
        }
    }
    public static func jsonReadOpt(_ rds : JSONRead<Element>) -> JSONRead<[Element?]> {
        return self.jsonReadValues().map { $0.map {try? rds.read($0)}}
    }
    public static func jsonReadOptFlat(_ rds : JSONRead<Element>) -> JSONRead<[Element]> {
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
    public func validate<T : JSONReadable>(_ v : [T].Type) throws -> [T] {
        return try self.validate(v.jsonRead())
    }
    public func validate<T : JSONReadable>(_ v : [T]?.Type) throws -> [T]? {
        return try self.validate([T].jsonRead().optional)
    }
    public func validate<T : JSONReadable>(_ v : [T?].Type) throws -> [T?] {
        return try self.validate([T].jsonReadOpt())
    }
}
public extension JSONPath {
    public func read<T: JSONReadable>(_ v : [T].Type) -> JSONRead<[T]> {
        return self.read(v.jsonRead())
    }
    public func read<T: JSONReadable>(_ v : [T]?.Type) -> JSONRead<[T]?> {
        return self.read([T].jsonRead().optional)
    }
    public func read<T: JSONReadable>(_ v : [T?].Type) -> JSONRead<[T?]> {
        return self.read([T].jsonReadOpt())
    }
}

