//
//  JSONFoundationTypesTests.swift
//
//
//  Created by Antoine Palazzolo on 06/11/15.
//  
//

import Foundation

import XCTest
@testable import FunctionalJSON
import FunctionalBuilder



class JSONFoundationTypesTests : XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testNSURL() {
        let json = try! jsonFromAny(["url" : "http://host.sub.com:80?query=2#fragment"])
        let url = try! json.validate(JSONPath("url").read(NSURL.jsonRead))
        XCTAssertEqual(url.absoluteString, "http://host.sub.com:80?query=2#fragment")
    }
    func testNSURLError() {
        let source = "sqdqs*àÈÏº†Ú®†d"
        let json = try! jsonFromAny(["url" : source])
        do {
            let url = try json.validate(JSONPath("url").read(NSURL.jsonRead))
            XCTFail("should throw error, \(url)")
        } catch {
            guard case JSONReadError.TransformError(let path, underlying: JSONFoundationTypesError.BadURLFormat(let url)) = error else {
                XCTFail("bad error type, should be not found, is \(error)")
                return
            }
            XCTAssertEqual(url, source)
            XCTAssertEqual(path, JSONPath("url"))
        }
    }
    func testNSDataBase64() {
        let source = "coucoudata".dataUsingEncoding(NSUTF8StringEncoding)!
        let base64encoded = source.base64EncodedStringWithOptions([])
        let json = try! jsonFromAny(["data" : base64encoded])
        let data = try! json.validate(JSONPath("data").read(NSData.jsonReadBase64))
        XCTAssertEqual(data, source)
    }
    func testNSDataBase64Error() {
        let source = "coucoudata'(§&é"
        let json = try! jsonFromAny(["data" : [source]])
        do {
            let data = try json.validate(JSONPath(["data",0]).read(NSData.jsonReadBase64))
            XCTFail("should throw error, \(data)")
        } catch {
            guard case JSONReadError.TransformError(let path, underlying: JSONFoundationTypesError.BadBase64Format(let baseBase64)) = error else {
                XCTFail("bad error type, should be not found, is \(error)")
                return
            }
            XCTAssertEqual(baseBase64, source)
            XCTAssertEqual(path, JSONPath(["data",0]))
        }
    }
    func testNSDateTimstamp() {
        let source = NSDate()
        
        //test int source
        let json = try! jsonFromAny(["date" : Int(source.timeIntervalSince1970)])
        let date = try! json.validate(JSONPath("date").read(NSDate.jsonReadTimestamp))
        XCTAssertEqualWithAccuracy(source.timeIntervalSince1970, date.timeIntervalSince1970, accuracy: 0.9999999999)
        
        //test double source
        let json2 = try! jsonFromAny(["date" : source.timeIntervalSince1970])
        let date2 = try! json2.validate(JSONPath("date").read(NSDate.jsonReadTimestamp))
        
        XCTAssertEqualWithAccuracy(source.timeIntervalSince1970,date2.timeIntervalSince1970,accuracy: 0.000999999)
    }
    func testNSDateMilli() {
        let source = NSDate()
        
        //test int source
        let json = try! jsonFromAny(["date" : Int(source.timeIntervalSince1970*1000)])
        let date = try! json.validate(JSONPath("date").read(NSDate.jsonReadTimestampMilli))
        print(source.timeIntervalSince1970, date.timeIntervalSince1970)
        XCTAssertEqualWithAccuracy(source.timeIntervalSince1970, date.timeIntervalSince1970, accuracy: 0.000999999)
        
        //test double source
        let json2 = try! jsonFromAny(["date" : source.timeIntervalSince1970*1000])
        let date2 = try! json2.validate(JSONPath("date").read(NSDate.jsonReadTimestampMilli))
        
        XCTAssertEqualWithAccuracy(source.timeIntervalSince1970,date2.timeIntervalSince1970,accuracy: 0.000999999)
    }
    func testNSDateFormat() {
        let source = NSDate()
        let format = NSDateFormatter()
        format.locale = NSLocale(localeIdentifier : "en_US_POSIX")
        format.dateFormat = "dd/MM/yyyy"
        let json = try! jsonFromAny(["date" : format.stringFromDate(source)])
        let date = try! json.validate(JSONPath("date").read(NSDate.jsonRead(format)))
        XCTAssertEqual(format.stringFromDate(source),format.stringFromDate(date))
    }
    func testNSDateFormatError() {
        let format = NSDateFormatter()
        format.locale = NSLocale(localeIdentifier : "en_US_POSIX")
        format.dateFormat = "dd/MM/yyyy"
        let json = try! jsonFromAny(["date" : "23/2016/12"])
        
        do {
            let date = try json.validate(JSONPath("date").read(NSDate.jsonRead(format)))
            XCTFail("should throw error, \(date)")
        } catch {
            guard case JSONReadError.TransformError(let path, underlying: JSONFoundationTypesError.BadDateFormat(let format, let input)) = error else {
                XCTFail("bad error type, should be not found, is \(error)")
                return
            }
            XCTAssertEqual(input, "23/2016/12")
            XCTAssertEqual(format, "dd/MM/yyyy")
            XCTAssertEqual(path, "date")
        }
    }
}
