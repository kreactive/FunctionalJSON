//
//  JSONReadComposition.swift
//  AKAds
//
//  Created by Antoine Palazzolo on 21/10/15.
//  
//

import Foundation
import FunctionalBuilder



extension JSONRead : ComposeType {
    public init<U : ComposeType where U.Input == JSONValue, U.Output == T>(_ compose : U) {
        self.init(transform: compose.pure)
    }
    public var pure : (JSONValue) throws -> T {
        return self.read
    }
}

extension JSONPath {
    public func read<T,U : ComposeType where U.Input == JSONValue, U.Output == T>(compose : U) -> JSONRead<T> {
        return JSONRead(path: self, source: JSONRead(compose))
    }
}
extension JSONValue {
    public func validate<T,U : ComposeType where U.Input == JSONValue, U.Output == T>(compose : U) throws -> T {
        return try self.validate(JSONRead(compose))
    }
}

public func <&><A,B>(a : JSONRead<A>, b : JSONRead<B>) -> Composed2<JSONValue,A,B> {
    return a.read <&> b.read
}