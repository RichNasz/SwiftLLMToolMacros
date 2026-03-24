// BasicUsage.swift
// Examples of SwiftLLMToolMacros usage
//
// This file demonstrates the core macros and types.
// All examples should compile when imported into a project
// that depends on SwiftLLMToolMacros.

import SwiftLLMToolMacros

// MARK: - Define Structured Arguments with @LLMToolArguments

/// Use @LLMToolArguments to define a struct whose properties map to a JSON Schema.
/// Each stored property becomes a schema property. Optional properties are
/// excluded from the "required" array.
@LLMToolArguments
struct WeatherQuery {
	@LLMToolGuide(description: "The city to get weather for")
	var location: String

	@LLMToolGuide(description: "Temperature unit", .anyOf(["celsius", "fahrenheit"]))
	var unit: String?
}

// MARK: - Define a Tool with @LLMTool

/// Use @LLMTool on a struct to generate an OpenAI-compatible tool definition.
/// The struct needs:
/// 1. A nested `Arguments` type (or typealias) conforming to `LLMToolArguments`
/// 2. A `call(arguments:)` method returning `ToolOutput`

/// Get the current weather for a location.
@LLMTool
struct GetWeather {
	typealias Arguments = WeatherQuery

	func call(arguments: WeatherQuery) async throws -> ToolOutput {
		// Your API call or business logic here
		ToolOutput(content: "Sunny, 72F in \(arguments.location)")
	}
}

// MARK: - Using the Generated Tool Definition

/// The macro generates a `toolDefinition` property that encodes to
/// OpenAI's expected JSON format:
///
/// ```json
/// {
///   "type": "function",
///   "function": {
///     "name": "get_weather",
///     "description": "Get the current weather for a location.",
///     "parameters": {
///       "type": "object",
///       "properties": {
///         "location": {
///           "type": "string",
///           "description": "The city to get weather for"
///         },
///         "unit": {
///           "type": "string",
///           "description": "Temperature unit",
///           "enum": ["celsius", "fahrenheit"]
///         }
///       },
///       "required": ["location"],
///       "additionalProperties": false
///     }
///   }
/// }
/// ```
func example() throws {
	let definition = GetWeather.toolDefinition

	let encoder = JSONEncoder()
	encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
	let data = try encoder.encode(definition)
	let json = String(data: data, encoding: .utf8)!
	print(json)
}

// MARK: - Nested @LLMToolArguments Types

@LLMToolArguments
struct Address {
	@LLMToolGuide(description: "Street address")
	var street: String

	@LLMToolGuide(description: "City name")
	var city: String

	@LLMToolGuide(description: "ZIP code")
	var zip: String
}

@LLMToolArguments
struct ShippingRequest {
	@LLMToolGuide(description: "Customer full name")
	var name: String

	var address: Address

	var items: [String]
}

// MARK: - Multiple Tools

/// Search the web for information.
@LLMTool
struct SearchWeb {
	@LLMToolArguments
	struct Arguments {
		@LLMToolGuide(description: "The search query")
		var query: String

		@LLMToolGuide(description: "Maximum number of results", .range(1...10))
		var maxResults: Int
	}

	func call(arguments: Arguments) async throws -> ToolOutput {
		ToolOutput(content: "Found results for: \(arguments.query)")
	}
}

/// Send an email to a recipient.
@LLMTool
struct SendEmail {
	@LLMToolArguments
	struct Arguments {
		@LLMToolGuide(description: "Recipient email address")
		var to: String

		@LLMToolGuide(description: "Email subject line")
		var subject: String

		@LLMToolGuide(description: "Email body text")
		var body: String
	}

	func call(arguments: Arguments) async throws -> ToolOutput {
		ToolOutput(content: "Email sent to \(arguments.to)")
	}
}
