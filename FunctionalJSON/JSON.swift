//
//  JSON.swift
//  AKAds
//
//  Created by Antoine Palazzolo on 19/10/15.
//  
//

import Foundation
import FunctionalBuilder

public struct JSONValue : JSONReadable {
    let underlying : Any?
    let path : JSONPath
    public init(data : Data, options : JSONSerialization.ReadingOptions = []) throws {
        underlying = try JSONSerialization.jsonObject(with: data, options: options)
        path = JSONPath([])
    }
    init(underlying : Any?, path : JSONPath) {
        self.underlying = {
            if underlying is NSNull {
                return nil
            } else {
                return underlying
            }
        }()
        self.path = path
    }
    public static let jsonRead = JSONRead(transform:{$0})
    
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
    public var isNull : Bool {
        return self.underlying == nil
    }
    public var subPathComponents : [JSONPathComponent] {
        switch self.underlying {
        case let dict as Dictionary<String,Any>:
            return dict.keys.map(JSONPathComponent.init(_:))
        case let array as [Any]:
            return array.indices.map(JSONPathComponent.init(_:))
        default:
            return []
        }
    }
    public func elementAtPath(_ path : JSONPath) -> JSONValue {
        var currentValue = self
        var currentPath = self.path
        guard currentValue.underlying != nil else {return JSONValue(underlying: nil,path : self.path + path)}
        for component in path.content {
            currentPath.append(component)
            switch (component, currentValue.underlying) {
            case (.key(let key), let v as NSDictionary):
                if let newValue = v[key] {
                    currentValue = JSONValue(underlying: newValue,path : currentPath)
                } else {
                    return JSONValue(underlying: nil,path : self.path + path)
                }
            case (.index(let index), let v as NSArray):
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
    public subscript(path: JSONPathComponent...) -> JSONValue {
        return self.elementAtPath(JSONPath(path))
    }
    public func validate<T>(_ rds : JSONRead<T>) throws -> T {
        return try rds.read(self)
    }
    public func validate<T : JSONReadable>(_ : T.Type) throws -> T {
        return try self.validate(T.jsonRead)
    }
    public func validate<T : JSONReadable>(_ : Optional<T>.Type) throws -> T? {
        return try self.validate(T.jsonRead.optional)
    }
}


public enum JSONPathComponent : ExpressibleByIntegerLiteral,ExpressibleByStringLiteral,Hashable,CustomStringConvertible {
    case key(String)
    case index(Int)
    init(_ value: String) {
        self = .key(value)
    }
    init(_ value: Int) {
        self = .index(value)
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
    public var description: String {
        switch self {
        case .key(let v) : return v
        case .index(let v) : return String(v)
        }
    }
    public var hashValue: Int {
        switch self {
        case .index(let index):
            return index.hashValue
        case .key(let key):
            return key.hashValue
        }
    }
}

public struct JSONPath : CustomStringConvertible, Equatable {
    public var description: String {
        return self.content.map{$0.description}.joined(separator: "/")
    }
    fileprivate var content : [JSONPathComponent]
    public init() {
        self.init([])
    }
    public init(_ component: String) {
        self.init([JSONPathComponent(component)])
    }
    public init(_ component: Int) {
        self.init([JSONPathComponent(component)])
    }
    public init(_ pathc: JSONPathComponent) {
        self.init([pathc])
    }
    public init(_ path: [JSONPathComponent]) {
        self.content = path
    }
    public init(_ path: JSONPathComponent...) {
        self.content = path
    }
    public mutating func append(_ component : JSONPathComponent) {
        self.content.append(component)
    }
    public mutating func append(_ path : JSONPath) {
        self.content += path.content
    }
    public func read() -> JSONRead<JSONValue> {
        return self.read(JSONValue.self)
    }
    public func read<T>(_ rds: JSONRead<T>) -> JSONRead<T> {
        return JSONRead<T>(path: self, source: rds)
    }
    public func read<T: JSONReadable>(_ : T.Type) -> JSONRead<T> {
        return self.read(T.jsonRead)
    }
    public func read<T: JSONReadable>(_ : T?.Type) -> JSONRead<T?> {
        return self.read(T.jsonRead.optional)
    }
}
extension JSONPath : ExpressibleByStringLiteral {
    
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
extension JSONPath : ExpressibleByIntegerLiteral {
    
    public init(integerLiteral value: IntegerLiteralType) {
        self.init(value)
    }
}
extension JSONPath : ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: JSONPathComponent...) {
        self.init(elements)
    }

}

public func ==(lhs : JSONPath,rhs : JSONPath) -> Bool {
    return lhs.content == rhs.content
}
public func ==(lhs : JSONPathComponent,rhs : JSONPathComponent) -> Bool {
    switch (lhs,rhs) {
    case (.key(let v1),.key(let v2)) where v1 == v2:
        return true
    case (.index(let v1),.index(let v2)) where v1 == v2:
        return true
    default :
        return false
    }
}

public func +(lhs: JSONPath, rhs: JSONPath) -> JSONPath {
    var result = lhs
    result.append(rhs)
    return result
}
public func +(lhs: JSONPath, rhs: JSONPathComponent) -> JSONPath {
    var result = lhs
    result.append(rhs)
    return result
}
public func +(lhs: JSONPath, rhs: Int) -> JSONPath {
    return lhs+JSONPathComponent(rhs)
}
public func +(lhs: JSONPath, rhs: String) -> JSONPath {
    return lhs+JSONPathComponent(rhs)
}

public enum JSONReadError : Error , CustomDebugStringConvertible {
    case valueNotFound(JSONPath)
    case badValueType(JSONPath)
    case transformError(JSONPath, underlying : Error)
    
    public var debugDescription : String {
        switch self {
        case .valueNotFound(let path):
            return "JSON Value not found -> \"\(path)\""
        case .badValueType(let path):
            return "JSON Bad value type -> \"\(path)\""
        case .transformError(let path, let error):
            return "JSON Transform error -> \"\(path)\" : \(error)"
        }
    }
}

public struct JSONValidationError : Error,CustomDebugStringConvertible {
    public var content : [JSONReadError]
    init() {
        content = []
    }
    init(_ readError : JSONReadError) {
        content = [readError]
    }
    init(_ composeError : ComposeError) {
        var ret = JSONValidationError()
        composeError.underlyingErrors.forEach {ret.append($0)}
        self = ret
    }
    mutating func append(_ error : Error) {
        switch error {
        case let x as JSONReadError:
            content.append(x)
        case let x as JSONValidationError:
            content.append(contentsOf: x.content)
        case let x as ComposeError:
            x.underlyingErrors.forEach {self.append($0)}
        default:
            fatalError("unknown error type")
        }
    }
    public var debugDescription : String {
        return "JSON Errors :\n\(content.map{"\t"+$0.debugDescription}.joined(separator: "\n"))"
    }
}


public protocol JSONReadable {
    static var jsonRead : JSONRead<Self> {get}
}

public struct JSONRead<T> {
    
    private let transform : (JSONValue) throws -> T
    private let path : JSONPath
    
    init(path :JSONPath = JSONPath([]), transform : @escaping (JSONValue) throws -> T) {
        self.transform = transform
        self.path = path
    }
    init(path :JSONPath = JSONPath([]), source : JSONRead<T>) {
        self.init(path: path+source.path, transform : source.transform)
    }
    func read(_ value : JSONValue) throws -> T {
        let value = value.elementAtPath(self.path)
        do {
            return try self.transform(value)
        } catch let x as JSONValidationError {
            throw x
        } catch let x as JSONReadError {
            throw JSONValidationError(x)
        } catch let x as ComposeError {
            throw JSONValidationError(x)
        } catch {
            throw JSONValidationError(JSONReadError.transformError(value.path, underlying: error))
        }
    }
    public func map<U>(_ t : @escaping (T) throws -> U) -> JSONRead<U> {
        return JSONRead<U>(path: self.path) { try t(self.transform($0)) }
    }
    public var optional : JSONRead<T?> {
        return JSONRead<T?>(path: self.path) { json -> T? in
            do {
                return try self.transform(json)
            } catch {
                return nil
            }
        }
    }
    public func withDefault(_ v : T) -> JSONRead<T> {
        return self.optional.map {$0 ?? v}
    }
}

