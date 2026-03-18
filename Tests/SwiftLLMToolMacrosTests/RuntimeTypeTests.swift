import Foundation
import Testing

@testable import SwiftLLMToolMacros

// MARK: - JSONSchemaValue Encoding Tests

@Suite("JSONSchemaValue Encoding")
struct JSONSchemaValueEncodingTests {

	@Test("String schema encodes correctly")
	func stringSchema() throws {
		let schema = JSONSchemaValue.string()
		let data = try JSONEncoder().encode(schema)
		let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
		#expect(json["type"] as? String == "string")
	}

	@Test("String schema with description encodes correctly")
	func stringSchemaWithDescription() throws {
		let schema = JSONSchemaValue.string(description: "A name")
		let data = try JSONEncoder().encode(schema)
		let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
		#expect(json["type"] as? String == "string")
		#expect(json["description"] as? String == "A name")
	}

	@Test("String schema with enum values encodes correctly")
	func stringSchemaWithEnumValues() throws {
		let schema = JSONSchemaValue.string(enumValues: ["a", "b", "c"])
		let data = try JSONEncoder().encode(schema)
		let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
		#expect(json["type"] as? String == "string")
		#expect(json["enum"] as? [String] == ["a", "b", "c"])
	}

	@Test("Integer schema encodes correctly")
	func integerSchema() throws {
		let schema = JSONSchemaValue.integer()
		let data = try JSONEncoder().encode(schema)
		let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
		#expect(json["type"] as? String == "integer")
	}

	@Test("Number schema encodes correctly")
	func numberSchema() throws {
		let schema = JSONSchemaValue.number()
		let data = try JSONEncoder().encode(schema)
		let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
		#expect(json["type"] as? String == "number")
	}

	@Test("Boolean schema encodes correctly")
	func booleanSchema() throws {
		let schema = JSONSchemaValue.boolean()
		let data = try JSONEncoder().encode(schema)
		let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
		#expect(json["type"] as? String == "boolean")
	}

	@Test("Null schema encodes correctly")
	func nullSchema() throws {
		let schema = JSONSchemaValue.null
		let data = try JSONEncoder().encode(schema)
		let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
		#expect(json["type"] as? String == "null")
	}

	@Test("Array schema encodes correctly")
	func arraySchema() throws {
		let schema = JSONSchemaValue.array(items: .string())
		let data = try JSONEncoder().encode(schema)
		let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
		#expect(json["type"] as? String == "array")
		let items = json["items"] as? [String: Any]
		#expect(items?["type"] as? String == "string")
	}

	@Test("Object schema encodes correctly")
	func objectSchema() throws {
		let schema = JSONSchemaValue.object(
			properties: [
				("name", .string(description: "The name")),
				("age", .integer()),
			],
			required: ["name", "age"]
		)
		let data = try JSONEncoder().encode(schema)
		let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
		#expect(json["type"] as? String == "object")
		#expect(json["additionalProperties"] as? Bool == false)
		#expect(json["required"] as? [String] == ["name", "age"])
		let props = json["properties"] as? [String: Any]
		#expect(props != nil)
		let nameProp = props?["name"] as? [String: Any]
		#expect(nameProp?["type"] as? String == "string")
	}
}

// MARK: - ToolDefinition Encoding Tests

@Suite("ToolDefinition Encoding")
struct ToolDefinitionEncodingTests {

	@Test("ToolDefinition encodes to OpenAI format")
	func toolDefinitionEncoding() throws {
		let definition = ToolDefinition(
			name: "get_weather",
			description: "Get weather",
			parameters: .object(
				properties: [
					("location", .string(description: "City name"))
				],
				required: ["location"]
			)
		)

		let encoder = JSONEncoder()
		encoder.outputFormatting = [.sortedKeys]
		let data = try encoder.encode(definition)
		let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

		#expect(json["type"] as? String == "function")

		let function = json["function"] as? [String: Any]
		#expect(function?["name"] as? String == "get_weather")
		#expect(function?["description"] as? String == "Get weather")

		let parameters = function?["parameters"] as? [String: Any]
		#expect(parameters?["type"] as? String == "object")
		#expect(parameters?["additionalProperties"] as? Bool == false)
		#expect(parameters?["required"] as? [String] == ["location"])

		let props = parameters?["properties"] as? [String: Any]
		let locationProp = props?["location"] as? [String: Any]
		#expect(locationProp?["type"] as? String == "string")
		#expect(locationProp?["description"] as? String == "City name")
	}
}

// MARK: - ToolOutput Tests

@Suite("ToolOutput")
struct ToolOutputTests {

	@Test("ToolOutput creation and equality")
	func toolOutputCreation() {
		let output1 = ToolOutput(content: "Hello")
		let output2 = ToolOutput(content: "Hello")
		let output3 = ToolOutput(content: "World")

		#expect(output1 == output2)
		#expect(output1 != output3)
		#expect(output1.content == "Hello")
	}
}

// MARK: - JSONSchemaValue Equality Tests

@Suite("JSONSchemaValue Equality")
struct JSONSchemaValueEqualityTests {

	@Test("Equal schemas are equal")
	func equalSchemas() {
		let a = JSONSchemaValue.string(description: "test")
		let b = JSONSchemaValue.string(description: "test")
		#expect(a == b)
	}

	@Test("Different schemas are not equal")
	func differentSchemas() {
		let a = JSONSchemaValue.string()
		let b = JSONSchemaValue.integer()
		#expect(a != b)
	}

	@Test("Object schemas with same properties are equal")
	func equalObjectSchemas() {
		let a = JSONSchemaValue.object(
			properties: [("name", .string())],
			required: ["name"]
		)
		let b = JSONSchemaValue.object(
			properties: [("name", .string())],
			required: ["name"]
		)
		#expect(a == b)
	}

	@Test("Null schemas are equal")
	func nullEquality() {
		#expect(JSONSchemaValue.null == JSONSchemaValue.null)
	}

	@Test("Null is not equal to other types")
	func nullNotEqualToOtherTypes() {
		#expect(JSONSchemaValue.null != JSONSchemaValue.string())
	}
}
