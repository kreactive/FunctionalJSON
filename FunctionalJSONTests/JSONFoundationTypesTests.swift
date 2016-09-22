//
//  JSONFoundationTypesTests.swift
//
//
//  Created by Antoine Palazzolo on 06/11/15.
//  
//

import Foundation

import XCTest
import FunctionalJSON
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
        let url = try! json.validate(JSONPath("url").read(URL.jsonRead))
        XCTAssertEqual(url.absoluteString, "http://host.sub.com:80?query=2#fragment")
    }
    func testNSURLError() {
        let source = "sqdqs*àÈÏº†Ú®†d"
        let json = try! jsonFromAny(["url" : source])
        do {
            let url = try json.validate(JSONPath("url").read(URL.jsonRead))
            XCTFail("should throw error, \(url)")
        } catch {
            guard let error = error as? JSONValidationError else {
                XCTFail("should always return JSONValidationError")
                return
            }
            
            guard case JSONReadError.transformError(let path, underlying: JSONFoundationTypesError.badURLFormat(let url)) = error.content.first! else {
                XCTFail("bad error type, should be not found, is \(error)")
                return
            }
            XCTAssertEqual(url, source)
            XCTAssertEqual(path, JSONPath("url"))
        }
    }
    func testNSDataBase64() {
        let source = "coucoudata".data(using: String.Encoding.utf8)!
        let base64encoded = source.base64EncodedString(options: [])
        let json = try! jsonFromAny(["data" : base64encoded])
        let data = try! json.validate(JSONPath("data").read(Data.jsonReadBase64))
        XCTAssertEqual(data, source)
    }
    func testNSDataBase64Error() {
        let source = "coucoudata'(§&é"
        let json = try! jsonFromAny(["data" : [source]])
        do {
            let data = try json.validate(JSONPath(["data",0]).read(Data.jsonReadBase64))
            XCTFail("should throw error, \(data)")
        } catch {
            guard let error = error as? JSONValidationError else {
                XCTFail("should always return JSONValidationError")
                return
            }
            guard case JSONReadError.transformError(let path, underlying: JSONFoundationTypesError.badBase64Format(let baseBase64)) = error.content.first! else {
                XCTFail("bad error type, should be not found, is \(error)")
                return
            }
            XCTAssertEqual(baseBase64, source)
            XCTAssertEqual(path, JSONPath(["data",0]))
        }
    }
    func testNSDateTimstamp() {
        let source = Date()
        
        //test int source
        let json = try! jsonFromAny(["date" : Int(source.timeIntervalSince1970)])
        let date = try! json.validate(JSONPath("date").read(Date.jsonReadTimestamp))
        XCTAssertEqualWithAccuracy(source.timeIntervalSince1970, date.timeIntervalSince1970, accuracy: 0.9999999999)
        
        //test double source
        let json2 = try! jsonFromAny(["date" : source.timeIntervalSince1970])
        let date2 = try! json2.validate(JSONPath("date").read(Date.jsonReadTimestamp))
        
        XCTAssertEqualWithAccuracy(source.timeIntervalSince1970,date2.timeIntervalSince1970,accuracy: 0.000999999)
    }
    func testNSDateMilli() {
        let source = Date()
        
        //test int source
        let json = try! jsonFromAny(["date" : NSNumber(value: Int64(source.timeIntervalSince1970*1000))])
        let date = try! json.validate(JSONPath("date").read(Date.jsonReadTimestampMilli))
        print(source.timeIntervalSince1970, date.timeIntervalSince1970)
        XCTAssertEqualWithAccuracy(source.timeIntervalSince1970, date.timeIntervalSince1970, accuracy: 0.000999999)
        
        //test double source
        let json2 = try! jsonFromAny(["date" : source.timeIntervalSince1970*1000])
        let date2 = try! json2.validate(JSONPath("date").read(Date.jsonReadTimestampMilli))
        
        XCTAssertEqualWithAccuracy(source.timeIntervalSince1970,date2.timeIntervalSince1970,accuracy: 0.000999999)
    }
    func testNSDateFormat() {
        let source = Date()
        let format = DateFormatter()
        format.locale = Locale(identifier : "en_US_POSIX")
        format.dateFormat = "dd/MM/yyyy"
        let json = try! jsonFromAny(["date" : format.string(from : source)])
        let date = try! json.validate(JSONPath("date").read(Date.jsonRead(format)))
        XCTAssertEqual(format.string(from: source),format.string(from : date))
    }
    func testNSDateFormatError() {
        let format = DateFormatter()
        format.locale = Locale(identifier : "en_US_POSIX")
        format.dateFormat = "dd/MM/yyyy"
        let json = try! jsonFromAny(["date" : "23/2016/12"])
        
        do {
            let date = try json.validate(JSONPath("date").read(Date.jsonRead(format)))
            XCTFail("should throw error, \(date)")
        } catch {
            guard let error = error as? JSONValidationError else {
                XCTFail("should always return JSONValidationError")
                return
            }
            
            guard case JSONReadError.transformError(let path, underlying: JSONFoundationTypesError.badDateFormat(let format, let input)) = error.content.first! else {
                XCTFail("bad error type, should be not found, is \(error)")
                return
            }
            XCTAssertEqual(input, "23/2016/12")
            XCTAssertEqual(format, "dd/MM/yyyy")
            XCTAssertEqual(path, "date")
        }
    }
}
