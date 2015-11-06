//
//  JSON.swift
//  AKAds
//
//  Created by Antoine Palazzolo on 19/10/15.
//  Copyright © 2015 Kreactive. All rights reserved.
//

import Foundation

public struct JSONValue {
    let underlying : AnyObject?
    let path : JSONPath
    public init(data : NSData) throws {
        underlying = try NSJSONSerialization.JSONObjectWithData(data, options: [])
        path = JSONPath([])
    }
    init(var underlying : AnyObject?, path : JSONPath) {
        if underlying is NSNull { underlying = nil }
        self.underlying = underlying
        self.path = path
    }
    
    public var isEmpty : Bool {
        switch self.underlying {
        case nil:
            return true
        case let x as NSDictionary where x.count == 0:
            return true
        case let x as NSArray where x.count == 0:
            return true
        default:
            return false
        }
    }
    
    public func elementAtPath(path : JSONPath) -> JSONValue {
        var currentValue = self
        var currentPath = self.path
        guard currentValue.underlying != nil else {return JSONValue(underlying: nil,path : self.path + path)}
        for component in path.content {
            currentPath.append(component)
            switch (component, currentValue.underlying) {
            case (.Key(let key), let v as Dictionary<String,AnyObject>):
                if let newValue = v[key] {
                    currentValue = JSONValue(underlying: newValue,path : currentPath)
                } else {
                    return JSONValue(underlying: nil,path : currentPath)
                }
            case (.Index(let index), let v as Array<AnyObject>):
                if index < v.count {
                    currentValue = JSONValue(underlying: v[index],path : currentPath)
                } else {
                    return JSONValue(underlying: nil,path : self.path + path)
                }
            default:
                return JSONValue(underlying: nil,path : self.path + path)
            }
        }
        return currentValue
    }
    public subscript(path: JSONPath) -> JSONValue {
        return self.elementAtPath(path)
    }
    public func validate<T>(rds : JSONRead<T>) throws -> T {
        return try rds.read(self)
    }
    public func validateOpt<T>(rds : JSONRead<T>) -> T? {
        do {
            return try self.validate(rds)
        } catch {
            return nil
        }
    }
    public func validate<T : JSONReadable>(_ : T.Type) throws -> T {
        return try self.validate(T.jsonRead)
    }
    public func validateOpt<T : JSONReadable>(_ : T.Type) -> T? {
        return self.validateOpt(T.jsonRead)
    }
}


public enum JSONPathComponent : IntegerLiteralConvertible,StringLiteralConvertible,Equatable {
    case Key(String)
    case Index(Int)
    init(_ value: String) {
        self = .Key(value)
    }
    init(_ value: Int) {
        self = Index(value)
    }
    public init(integerLiteral value: IntegerLiteralType) {
        self.init(value)
    }
    public init(stringLiteral value: StringLiteralType) {
        self.init(String(value))
    }
    public typealias UnicodeScalarLiteralType = StringLiteralType
    public init(unicodeScalarLiteral value: UnicodeScalarLiteralType) {
        self.init(stringLiteral : value)
    }
    public typealias ExtendedGraphemeClusterLiteralType = StringLiteralType
    public init(extendedGraphemeClusterLiteral value: ExtendedGraphemeClusterLiteralType) {
        self.init(stringLiteral : value)
    }
}

public struct JSONPath : CustomStringConvertible, Equatable {
    public var description: String {
        return self.content.map{String($0)}.joinWithSeparator("/")
    }
    private var content : [JSONPathComponent]
    public init() {
        self.init([])
    }
    public init(_ component: String) {
        self.init(JSONPathComponent(component))
    }
    public init(_ component: Int) {
        self.init(JSONPathComponent(component))
    }
    public init(_ pathc: JSONPathComponent) {
        self.init([pathc])
    }
    public init(_ path: [JSONPathComponent]) {
        self.content = path
    }
    public mutating func append(component : JSONPathComponent) {
        self.content.append(component)
    }
    public mutating func append(path : JSONPath) {
        self.content += path.content
    }
    public func read<T>(rds: JSONRead<T>) -> JSONRead<T> {
        return JSONRead<T>(path: self, source: rds)
    }
    public func readOpt<T>(rds: JSONRead<T>) -> JSONRead<T?> {
        return JSONRead<T>(path: self, source: rds).toOpt()
    }
    public func read<T: JSONReadable>(_ : T.Type) -> JSONRead<T> {
        return self.read(T.jsonRead)
    }
    public func readOpt<T: JSONReadable>(_ : T.Type) -> JSONRead<T?> {
        return self.readOpt(T.jsonRead)
    }
}
extension JSONPath : StringLiteralConvertible {
    
    public init(stringLiteral value: StringLiteralType) {
        self.init(String(value))
    }
    public typealias UnicodeScalarLiteralType = StringLiteralType
    public init(unicodeScalarLiteral value: UnicodeScalarLiteralType) {
        self.init(stringLiteral : value)
    }
    public typealias ExtendedGraphemeClusterLiteralType = StringLiteralType
    public init(extendedGraphemeClusterLiteral value: ExtendedGraphemeClusterLiteralType) {
        self.init(stringLiteral : value)
    }

}
extension JSONPath : IntegerLiteralConvertible {
    
    public init(integerLiteral value: IntegerLiteralType) {
        self.init(value)
    }
}
extension JSONPath : ArrayLiteralConvertible {
    public init(arrayLiteral elements: JSONPathComponent...) {
        self.init(elements)
    }

}

public func ==(lhs : JSONPath,rhs : JSONPath) -> Bool {
    return lhs.content == rhs.content
}
public func ==(lhs : JSONPathComponent,rhs : JSONPathComponent) -> Bool {
    switch (lhs,rhs) {
    case (.Key(let v1),.Key(let v2)) where v1 == v2:
        return true
    case (.Index(let v1),.Index(let v2)) where v1 == v2:
        return true
    default :
        return false
    }
}

public func +(var lhs: JSONPath, rhs: JSONPath) -> JSONPath {
    lhs.append(rhs)
    return lhs
}
public func +(var lhs: JSONPath, rhs: JSONPathComponent) -> JSONPath {
    lhs.append(rhs)
    return lhs
}
public func +(lhs: JSONPath, rhs: Int) -> JSONPath {
    return lhs+JSONPathComponent(rhs)
}
public func +(lhs: JSONPath, rhs: String) -> JSONPath {
    return lhs+JSONPathComponent(rhs)
}

public enum JSONReadError : ErrorType {
    case ValueNotFound(JSONPath)
    case BadValueType(JSONPath)
    case TransformError(JSONPath, underlying : ErrorType)
    case CompositionError([JSONReadError])
}

public protocol JSONReadable {
    static var jsonRead : JSONRead<Self> {get}
}

public struct JSONRead<T> {
    
    private let transform : (JSONValue) throws -> T
    private let path : JSONPath
    
    init(path :JSONPath = JSONPath([]), transform : (JSONValue) throws -> T) {
        self.transform = transform
        self.path = path
    }
    init(path :JSONPath = JSONPath([]), source : JSONRead<T>) {
        self.init(path: path, transform : source.transform)
    }
    
    func read(value : JSONValue) throws -> T {
        let value = value.elementAtPath(self.path)
        do {
            return try self.transform(value)
        } catch let error as JSONReadError {
            throw error
        } catch {
            throw JSONReadError.TransformError(value.path, underlying: error)
        }
    }
    public func map<U>(t : T throws -> U) -> JSONRead<U> {
        return JSONRead<U>(path: self.path) { try t(self.transform($0)) }
    }
    public func toOpt() -> JSONRead<T?> {
        return JSONRead<T?>(path: self.path) { json -> T? in
            do {
                return try self.transform(json)
            } catch {
                return nil
            }
        }
    }
}


