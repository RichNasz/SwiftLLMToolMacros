// BasicUsage.swift
// Examples of using SwiftChatCompletionsMacros
//
// NOTE: This file is for documentation purposes and is not compiled as part of
// the package. To use these examples, add SwiftChatCompletionsMacros as a
// dependency to your project.

import SwiftChatCompletionsMacros

// MARK: - Define Structured Arguments with @Generable

/// Use @Generable to define a struct whose properties map to a JSON Schema.
/// Each stored property becomes a schema property. Optional properties are
/// excluded from the "required" array.
@Generable
struct WeatherQuery {
	@Guide(description: "The city to get weather for")
	var location: String

	@Guide(description: "Temperature unit", .anyOf(["celsius", "fahrenheit"]))
	var unit: String?
}

// MARK: - Define a Tool with @Tool

/// Use @Tool on a struct to generate an OpenAI-compatible tool definition.
/// The struct needs:
/// 1. A nested `Arguments` type (or typealias) conforming to `Generable`
/// 2. A `call(arguments:)` method returning `ToolOutput`

/// Get the current weather for a location.
@Tool
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

// MARK: - Nested @Generable Types

@Generable
struct Address {
	@Guide(description: "Street address")
	var street: String

	@Guide(description: "City name")
	var city: String

	@Guide(description: "ZIP code")
	var zip: String
}

@Generable
struct ShippingRequest {
	@Guide(description: "Customer full name")
	var name: String

	var address: Address

	var items: [String]
}

// MARK: - Multiple Tools

/// Search the web for information.
@Tool
struct SearchWeb {
	@Generable
	struct Arguments {
		@Guide(description: "The search query")
		var query: String

		@Guide(description: "Maximum number of results", .range(1...10))
		var maxResults: Int
	}

	func call(arguments: Arguments) async throws -> ToolOutput {
		ToolOutput(content: "Found results for: \(arguments.query)")
	}
}

/// Send an email to a recipient.
@Tool
struct SendEmail {
	@Generable
	struct Arguments {
		@Guide(description: "Recipient email address")
		var to: String

		@Guide(description: "Email subject line")
		var subject: String

		@Guide(description: "Email body text")
		var body: String
	}

	func call(arguments: Arguments) async throws -> ToolOutput {
		ToolOutput(content: "Email sent to \(arguments.to)")
	}
}
