
# FunctionalJSON
FunctionalJSON is a fast and functional JSON library for Swift.<br />
Inspired by the play/scala JSON lib. <br />

# Features

- Simple reads composition to build complex structures
- Full JSON validation & easy debugging
- Easy navigation into the JSON tree
- Simple syntax
- Fast !

[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

# Usage

**json :**
```json
{
	"customers" : [
		{
			"name" : "alice",
			"age" : 20,
			"transactions" : [{"id" : 21312},{"id" : 32414},{"id" : 23443}]
		},
		{
			"name" : "bob",
			"transactions" : []
		},
		{
			"name" : "chris",
			"age" : 34,
			"transactions" : [{"id" : 23455},{"id" : 23452}]
		}
	] 
}
```

**swift :**

```swift
import FunctionalJSON
import FunctionalBuilder

struct Person : JSONReadable {
	let name : String
	let age : Int?
	let transactions : [Transaction]
	
	static let jsonRead = JSONRead(
		JSONPath("name").read(String) <&>
		JSONPath("age").read(Int?) <&>
		JSONPath("transactions").read([Transaction])
	).map(Person.init)
}
struct Transaction : JSONReadable {
	let identifier : Int64
	static let jsonRead = JSONPath("id").read(Int64).map(Transaction.init)
}

let jsonData : NSData = ... 
let json = try JSONValue(data : jsonData)

let persons : [Person] = try json["customers"].validate([Person])  
```
# JSONValue
`JSONValue` struct contains parsed json data.
```swift
let jsonData : NSData = ... 
let json = try JSONValue(data : jsonData)
```
The input data is parsed using Foundation NSJSONSerialization.<br />
Parsing option can be passed as initializer parameter :
```let json = try JSONValue(data: jsonData, options : [.AllowFragments])```

### Navigate into the json tree

Navigate using subscript and a `JSONPath` :<br />
`let jsonElement : JSONValue = json[JSONPath("customers",0)]` <br />
or<br />
`let jsonElement : JSONValue = json["customers"][0]` <br />
or :<br />
`let jsonElement : JSONValue = json["customers",0]`

`JSONPath` is wrapper around a array of `JSONPathComponent`<br />
```swift
public enum JSONPathComponent {
   	case Key(String)
   	case Index(Int)
}
```
A `Key` value represent the key of json object and an `Index` represent the index in a json array. 

This method will always return a `JSONValue`, even if there's no corresponding value in the json tree.<br />
<br />
The `isNull` property will return `true` if there is no value. 
`let isNull : Bool = json["customers",1992002].isNull`
<br />
<br />
The `isEmpty` property will return `true` if there is no value of if the underlying value is an empty object or array. <br />
`let isEmpty : Bool = json["customers"].isEmpty`

 
# JSONRead
`JSONRead<T>` struct define how a value is read from a json. It contains the path to the element and the function that will validate and transform that element to the target value of type `T`.<br />
All json base types reads are implemented and mapped to the swift types. (`Int..`,`Double`,`Float`,`String`,`Array`) <br/><br/>
`JSONRead` can be transformed using `map<U>(t : T throws -> U) -> JSONRead<U>`


### Example

- Read an `Int` value at path **"customers"/0/"age"** : <br />
`let read : JSONRead<Int> = JSONPath(["customers",0,"age"]).read(Int)` <br />

- Transform to an NSDate read

```swift
let readDate : JSONRead<NSDate> = read.map {
	guard let date = NSCalendar.currentCalendar().dateByAddingUnit(.Year,
		value: -$0,
			toDate: NSDate(),
               options: []) else {
               throw Error.DateError
           }
           return date
       }
```
        
- Get an optional read if it fails:
`let optionalRead : JSONRead<NSDate?> = readDate.optional`

- Or a default value if the read fails :
`let defaultDateRead : JSONRead<NSDate> = readDate.withDefault(NSDate())`

### Usage
```swift
let jsonValue : JSONValue = ...
do {
	let date : NSDate = try jsonValue.validate(defaultDateRead)
} catch {
	...
}
```
# JSONReadable
```swift
public protocol JSONReadable {
	static var jsonRead : JSONRead<Self> {get}
}
```
	
The `JSONReadable` protocol is used to get the **default** read of a type. It can't be implemented on non-final `class` because subclass can't redeclare jsonRead static var for its type.<br />
This protocol enable the "type" syntaxe in `JSONValue` validation and `JSONPath` read methods :<br /> `JSONPath("name").read(String)`<br /> instead of <br />`JSONPath("name").read(String.jsonRead)`

# Composition
Composition and the `<&>` operator come from the `FunctionalBuilder` module. This module is used to compose generic throwing functions and accumulate errors. You can compose up to 10 reads.
```swift
let read : JSONRead<(String,Int?,[Transaction])> = JSONRead(
	JSONPath("name").read(String) <&>
	JSONPath("age").read(Int?) <&>
	JSONPath("transactions").read([Transaction])
)
```
# Validation
Unlike most json libs, the validation does not stop at the first error. Instead, all error are accumulated and reported as a flat array of errors at the end.

Validating this JSON with the previous reads :
```json
{
   	"name" : 31232,
   	"age" : 30,
   	"transactions" : [{"identifier" : 23455},{"id" : 23455}]
}
```
	
<br />
```swift
let json = try JSONValue(data : jsonData)
do {
	try json.validate(Person)
} catch {
	print(error)
}
```

This will throw a `JSONValidationError` that contains 2 errors :

	JSON Errors :
		JSON Bad value type -> "name"
		JSON Value not found -> "transactions/0/id"

