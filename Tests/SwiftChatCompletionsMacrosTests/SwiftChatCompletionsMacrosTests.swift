import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(SwiftChatCompletionsMacrosPlugin)
import SwiftChatCompletionsMacrosPlugin

let testMacros: [String: any Macro.Type] = [
	"ChatCompletionsToolArguments": GenerableMacro.self,
	"ChatCompletionsTool": ToolMacro.self,
	"ChatCompletionsToolGuide": GuideMacro.self,
]
#endif

// MARK: - @ChatCompletionsToolArguments Macro Expansion Tests

final class GenerableMacroTests: XCTestCase {

	#if canImport(SwiftChatCompletionsMacrosPlugin)

	func testGenerableWithPrimitiveTypes() throws {
		assertMacroExpansion(
			"""
			@ChatCompletionsToolArguments
			struct Query {
				var name: String
				var age: Int
				var score: Double
				var active: Bool
			}
			""",
			expandedSource: """
			struct Query {
				var name: String
				var age: Int
				var score: Double
				var active: Bool

			    public static var jsonSchema: JSONSchemaValue {
			    \t.object(
			    \t\tproperties: [("name", .string()), ("age", .integer()), ("score", .number()), ("active", .boolean())],
			    \t\trequired: ["name", "age", "score", "active"]
			    \t)
			    }
			}

			extension Query: ChatCompletionsToolArguments, Codable, Sendable {
			}
			""",
			macros: testMacros
		)
	}

	func testGenerableWithOptionalProperty() throws {
		assertMacroExpansion(
			"""
			@ChatCompletionsToolArguments
			struct Query {
				var name: String
				var nickname: String?
			}
			""",
			expandedSource: """
			struct Query {
				var name: String
				var nickname: String?

			    public static var jsonSchema: JSONSchemaValue {
			    \t.object(
			    \t\tproperties: [("name", .string()), ("nickname", .string())],
			    \t\trequired: ["name"]
			    \t)
			    }
			}

			extension Query: ChatCompletionsToolArguments, Codable, Sendable {
			}
			""",
			macros: testMacros
		)
	}

	func testGenerableWithGuideDescription() throws {
		assertMacroExpansion(
			"""
			@ChatCompletionsToolArguments
			struct Query {
				@ChatCompletionsToolGuide(description: "The city name")
				var location: String
			}
			""",
			expandedSource: """
			struct Query {
				var location: String

			    public static var jsonSchema: JSONSchemaValue {
			    \t.object(
			    \t\tproperties: [("location", .string(description: "The city name"))],
			    \t\trequired: ["location"]
			    \t)
			    }
			}

			extension Query: ChatCompletionsToolArguments, Codable, Sendable {
			}
			""",
			macros: testMacros
		)
	}

	func testGenerableWithArrayType() throws {
		assertMacroExpansion(
			"""
			@ChatCompletionsToolArguments
			struct Query {
				var tags: [String]
			}
			""",
			expandedSource: """
			struct Query {
				var tags: [String]

			    public static var jsonSchema: JSONSchemaValue {
			    \t.object(
			    \t\tproperties: [("tags", .array(items: .string()))],
			    \t\trequired: ["tags"]
			    \t)
			    }
			}

			extension Query: ChatCompletionsToolArguments, Codable, Sendable {
			}
			""",
			macros: testMacros
		)
	}

	func testGenerableOnNonStructEmitsError() throws {
		assertMacroExpansion(
			"""
			@ChatCompletionsToolArguments
			class Query {
				var name: String = ""
			}
			""",
			expandedSource: """
			class Query {
				var name: String = ""
			}
			""",
			diagnostics: [
				DiagnosticSpec(
					message: "@ChatCompletionsToolArguments can only be applied to structs",
					line: 1,
					column: 1
				)
			],
			macros: testMacros
		)
	}

	func testGenerableWithGuideEnumConstraint() throws {
		assertMacroExpansion(
			"""
			@ChatCompletionsToolArguments
			struct Query {
				@ChatCompletionsToolGuide(description: "Temperature unit", .anyOf(["celsius", "fahrenheit"]))
				var unit: String
			}
			""",
			expandedSource: """
			struct Query {
				var unit: String

			    public static var jsonSchema: JSONSchemaValue {
			    \t.object(
			    \t\tproperties: [("unit", .string(description: "Temperature unit", enumValues: ["celsius", "fahrenheit"]))],
			    \t\trequired: ["unit"]
			    \t)
			    }
			}

			extension Query: ChatCompletionsToolArguments, Codable, Sendable {
			}
			""",
			macros: testMacros
		)
	}

	func testGenerableWithGuideRangeConstraint() throws {
		assertMacroExpansion(
			"""
			@ChatCompletionsToolArguments
			struct Query {
				@ChatCompletionsToolGuide(description: "Number of results", .range(1...100))
				var count: Int
			}
			""",
			expandedSource: """
			struct Query {
				var count: Int

			    public static var jsonSchema: JSONSchemaValue {
			    \t.object(
			    \t\tproperties: [("count", .integer(description: "Number of results", minimum: 1, maximum: 100))],
			    \t\trequired: ["count"]
			    \t)
			    }
			}

			extension Query: ChatCompletionsToolArguments, Codable, Sendable {
			}
			""",
			macros: testMacros
		)
	}

	func testGenerableWithGuideDoubleRangeConstraint() throws {
		assertMacroExpansion(
			"""
			@ChatCompletionsToolArguments
			struct Query {
				@ChatCompletionsToolGuide(description: "Temperature value", .doubleRange(0.0...2.0))
				var temperature: Double
			}
			""",
			expandedSource: """
			struct Query {
				var temperature: Double

			    public static var jsonSchema: JSONSchemaValue {
			    \t.object(
			    \t\tproperties: [("temperature", .number(description: "Temperature value", minimum: 0.0, maximum: 2.0))],
			    \t\trequired: ["temperature"]
			    \t)
			    }
			}

			extension Query: ChatCompletionsToolArguments, Codable, Sendable {
			}
			""",
			macros: testMacros
		)
	}

	func testGenerableWithNestedGenerable() throws {
		assertMacroExpansion(
			"""
			@ChatCompletionsToolArguments
			struct Outer {
				var inner: InnerType
			}
			""",
			expandedSource: """
			struct Outer {
				var inner: InnerType

			    public static var jsonSchema: JSONSchemaValue {
			    \t.object(
			    \t\tproperties: [("inner", InnerType.jsonSchema)],
			    \t\trequired: ["inner"]
			    \t)
			    }
			}

			extension Outer: ChatCompletionsToolArguments, Codable, Sendable {
			}
			""",
			macros: testMacros
		)
	}

	#else
	func testMacroNotAvailable() throws {
		XCTFail("SwiftChatCompletionsMacrosPlugin module not available")
	}
	#endif
}

// MARK: - @ChatCompletionsTool Macro Expansion Tests

final class ToolMacroTests: XCTestCase {

	#if canImport(SwiftChatCompletionsMacrosPlugin)

	func testToolWithNestedArguments() throws {
		assertMacroExpansion(
			"""
			/// Get the current weather for a location.
			@ChatCompletionsTool
			struct GetWeather {
				@ChatCompletionsToolArguments
				struct Arguments {
					var location: String
				}

				func call(arguments: Arguments) async throws -> ToolOutput {
					ToolOutput(content: "Sunny")
				}
			}
			""",
			expandedSource: """
			/// Get the current weather for a location.
			struct GetWeather {
				struct Arguments {
					var location: String

				    public static var jsonSchema: JSONSchemaValue {
				    \t.object(
				    \t\tproperties: [("location", .string())],
				    \t\trequired: ["location"]
				    \t)
				    }
				}

				func call(arguments: Arguments) async throws -> ToolOutput {
					ToolOutput(content: "Sunny")
				}

			    public static let name: String = "get_weather"

			    public static let description: String = "Get the current weather for a location."

			    public static var toolDefinition: ToolDefinition {
			    \tToolDefinition(
			    \t\tname: name,
			    \t\tdescription: description,
			    \t\tparameters: Arguments.jsonSchema
			    \t)
			    }
			}

			extension GetWeather.Arguments: ChatCompletionsToolArguments, Codable, Sendable {
			}

			extension GetWeather: ChatCompletionsTool {
			}
			""",
			macros: testMacros
		)
	}

	func testToolOnNonStructEmitsError() throws {
		assertMacroExpansion(
			"""
			@ChatCompletionsTool
			class MyTool {
			}
			""",
			expandedSource: """
			class MyTool {
			}
			""",
			diagnostics: [
				DiagnosticSpec(
					message: "@ChatCompletionsTool can only be applied to structs",
					line: 1,
					column: 1
				)
			],
			macros: testMacros
		)
	}

	func testToolPascalCaseToSnakeCase() throws {
		assertMacroExpansion(
			"""
			/// Search the web.
			@ChatCompletionsTool
			struct SearchWebResults {
				@ChatCompletionsToolArguments
				struct Arguments {
					var query: String
				}

				func call(arguments: Arguments) async throws -> ToolOutput {
					ToolOutput(content: "results")
				}
			}
			""",
			expandedSource: """
			/// Search the web.
			struct SearchWebResults {
				struct Arguments {
					var query: String

				    public static var jsonSchema: JSONSchemaValue {
				    \t.object(
				    \t\tproperties: [("query", .string())],
				    \t\trequired: ["query"]
				    \t)
				    }
				}

				func call(arguments: Arguments) async throws -> ToolOutput {
					ToolOutput(content: "results")
				}

			    public static let name: String = "search_web_results"

			    public static let description: String = "Search the web."

			    public static var toolDefinition: ToolDefinition {
			    \tToolDefinition(
			    \t\tname: name,
			    \t\tdescription: description,
			    \t\tparameters: Arguments.jsonSchema
			    \t)
			    }
			}

			extension SearchWebResults.Arguments: ChatCompletionsToolArguments, Codable, Sendable {
			}

			extension SearchWebResults: ChatCompletionsTool {
			}
			""",
			macros: testMacros
		)
	}

	#else
	func testMacroNotAvailable() throws {
		XCTFail("SwiftChatCompletionsMacrosPlugin module not available")
	}
	#endif
}

// MARK: - @ChatCompletionsToolGuide Macro Expansion Tests

final class GuideMacroTests: XCTestCase {

	#if canImport(SwiftChatCompletionsMacrosPlugin)

	func testGuideIsMarkerMacro() throws {
		assertMacroExpansion(
			"""
			@ChatCompletionsToolGuide(description: "A test description")
			var name: String
			""",
			expandedSource: """
			var name: String
			""",
			macros: testMacros
		)
	}

	#else
	func testMacroNotAvailable() throws {
		XCTFail("SwiftChatCompletionsMacrosPlugin module not available")
	}
	#endif
}
