//
//  JSONFoundationTypes.swift
//  AKAds
//
//  Created by Antoine Palazzolo on 22/10/15.
//  Copyright © 2015 Kreactive. All rights reserved.
//

import Foundation


public enum JSONFoundationTypesError : ErrorType {
    case BadURLFormat(String)
}
private typealias Error = JSONFoundationTypesError

public extension NSURL {
    static var jsonRead : JSONRead<NSURL> = String.jsonRead.map { s in try NSURL(string : s) ?? {throw Error.BadURLFormat(s)}()}
}
