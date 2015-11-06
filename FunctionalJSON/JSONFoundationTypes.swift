//
//  JSONFoundationTypes.swift
//  AKAds
//
//  Created by Antoine Palazzolo on 22/10/15.
//  
//

import Foundation


public enum JSONFoundationTypesError : ErrorType {
    case BadURLFormat(String)
    case BadBase64Format(String)
    case BadDateFormat(usedFormat : String, input : String)

}
private typealias Error = JSONFoundationTypesError

public extension NSURL {
    static let jsonRead : JSONRead<NSURL> = String.jsonRead.map { s in try NSURL(string : s) ?? {throw Error.BadURLFormat(s)}()}
}

public extension NSData {
    static let jsonReadBase64 : JSONRead<NSData> = NSData.jsonReadBase64()
    static func jsonReadBase64(options : NSDataBase64DecodingOptions = []) -> JSONRead<NSData> {
        return String.jsonRead.map { s in
            try NSData(base64EncodedString: s, options: options) ?? {throw Error.BadBase64Format(s)}()
        }
    }
}


public extension NSDate {
    
    //read double and integer values of timestamps (seconds from 1970)
    static let jsonReadTimestamp : JSONRead<NSDate> = Double.jsonRead.map { NSDate(timeIntervalSince1970: NSTimeInterval($0))}
    
    //read double and integer values of millisecondes timestamps (millisecondes from 1970)
    static let jsonReadTimestampMilli : JSONRead<NSDate> = Double.jsonRead.map { NSDate(timeIntervalSince1970: NSTimeInterval($0)/1000.0)}

    static func jsonRead(format : NSDateFormatter) -> JSONRead<NSDate> {
        return String.jsonRead.map { s in
            try format.dateFromString(s) ?? {throw Error.BadDateFormat(usedFormat : format.dateFormat ?? "",input :s)}()
        }
    }
}