//
//  JSONFoundationTypes.swift
//  AKAds
//
//  Created by Antoine Palazzolo on 22/10/15.
//  
//

import Foundation


public enum JSONFoundationTypesError : Error {
    case badURLFormat(String)
    case badBase64Format(String)
    case badDateFormat(usedFormat : String, input : String)

}

extension URL : JSONReadable {
    public static let jsonRead : JSONRead<URL> = String.jsonRead.map { s in
        try URLComponents(string: s)?.url ?? {throw JSONFoundationTypesError.badURLFormat(s)}()
    }
}

public extension Data {
    static let jsonReadBase64 : JSONRead<Data> = Data.jsonReadBase64()
    static func jsonReadBase64(_ options : Data.Base64DecodingOptions = []) -> JSONRead<Data> {
        return String.jsonRead.map { s in
            guard let data = Data(base64Encoded: s, options: options) else {
                throw JSONFoundationTypesError.badBase64Format(s)
            }
            return data
        }
    }
}


public extension Date {
    
    //read double and integer values of timestamps (seconds from 1970)
    static let jsonReadTimestamp : JSONRead<Date> = Double.jsonRead.map { Date(timeIntervalSince1970: TimeInterval($0))}
    
    //read double and integer values of millisecondes timestamps (millisecondes from 1970)
    static let jsonReadTimestampMilli : JSONRead<Date> = Double.jsonRead.map { Date(timeIntervalSince1970: TimeInterval($0)/1000.0)}

    static func jsonRead(_ format : DateFormatter) -> JSONRead<Date> {
        return String.jsonRead.map { s in
            try format.date(from: s) ?? {throw JSONFoundationTypesError.badDateFormat(usedFormat : format.dateFormat ?? "",input :s)}()
        }
    }
}
