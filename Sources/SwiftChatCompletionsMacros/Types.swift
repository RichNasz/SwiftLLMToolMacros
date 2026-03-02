/// JSON Schema value representation for OpenAI-compatible tool definitions.
///
/// Constructed at compile time by `@Generable` macro expansion. Encodes to
/// OpenAI-compatible JSON Schema at runtime via `Encodable` conformance.
public indirect enum JSONSchemaValue: Sendable, Equatable {
	case object(properties: [(String, JSONSchemaValue)], required: [String])
	case array(items: JSONSchemaValue)
	case string(description: String? = nil, enumValues: [String]? = nil)
	case integer(description: String? = nil, minimum: Int? = nil, maximum: Int? = nil)
	case number(description: String? = nil, minimum: Double? = nil, maximum: Double? = nil)
	case boolean(description: String? = nil)

	public static func == (lhs: JSONSchemaValue, rhs: JSONSchemaValue) -> Bool {
		switch (lhs, rhs) {
		case let (.object(lp, lr), .object(rp, rr)):
			guard lr == rr, lp.count == rp.count else { return false }
			for (l, r) in zip(lp, rp) {
				if l.0 != r.0 || l.1 != r.1 { return false }
			}
			return true
		case let (.array(li), .array(ri)):
			return li == ri
		case let (.string(ld, le), .string(rd, re)):
			return ld == rd && le == re
		case let (.integer(ld, lmin, lmax), .integer(rd, rmin, rmax)):
			return ld == rd && lmin == rmin && lmax == rmax
		case let (.number(ld, lmin, lmax), .number(rd, rmin, rmax)):
			return ld == rd && lmin == rmin && lmax == rmax
		case let (.boolean(ld), .boolean(rd)):
			return ld == rd
		default:
			return false
		}
	}
}

extension JSONSchemaValue: Encodable {
	public func encode(to encoder: any Encoder) throws {
		var container = encoder.singleValueContainer()
		switch self {
		case let .object(properties, required):
			var dict: [String: AnyCodable] = [
				"type": AnyCodable("object"),
				"additionalProperties": AnyCodable(false),
			]
			var props: [String: AnyCodable] = [:]
			for (key, value) in properties {
				props[key] = AnyCodable(value)
			}
			dict["properties"] = AnyCodable(props)
			if !required.isEmpty {
				dict["required"] = AnyCodable(required)
			}
			try container.encode(dict)
		case let .array(items):
			let dict: [String: AnyCodable] = [
				"type": AnyCodable("array"),
				"items": AnyCodable(items),
			]
			try container.encode(dict)
		case let .string(description, enumValues):
			var dict: [String: AnyCodable] = ["type": AnyCodable("string")]
			if let description { dict["description"] = AnyCodable(description) }
			if let enumValues { dict["enum"] = AnyCodable(enumValues) }
			try container.encode(dict)
		case let .integer(description, minimum, maximum):
			var dict: [String: AnyCodable] = ["type": AnyCodable("integer")]
			if let description { dict["description"] = AnyCodable(description) }
			if let minimum { dict["minimum"] = AnyCodable(minimum) }
			if let maximum { dict["maximum"] = AnyCodable(maximum) }
			try container.encode(dict)
		case let .number(description, minimum, maximum):
			var dict: [String: AnyCodable] = ["type": AnyCodable("number")]
			if let description { dict["description"] = AnyCodable(description) }
			if let minimum { dict["minimum"] = AnyCodable(minimum) }
			if let maximum { dict["maximum"] = AnyCodable(maximum) }
			try container.encode(dict)
		case let .boolean(description):
			var dict: [String: AnyCodable] = ["type": AnyCodable("boolean")]
			if let description { dict["description"] = AnyCodable(description) }
			try container.encode(dict)
		}
	}
}

/// Internal type-erased wrapper for encoding heterogeneous dictionaries.
struct AnyCodable: Encodable, Sendable {
	private let _encode: @Sendable (any Encoder) throws -> Void

	init(_ value: some Encodable & Sendable) {
		self._encode = { encoder in
			try value.encode(to: encoder)
		}
	}

	func encode(to encoder: any Encoder) throws {
		try _encode(encoder)
	}
}

/// Represents the output of a tool call.
public struct ToolOutput: Sendable, Equatable {
	/// The string content returned by the tool.
	public let content: String

	public init(content: String) {
		self.content = content
	}
}

/// An OpenAI-compatible tool definition that encodes to the
/// `{"type":"function","function":{...}}` format.
public struct ToolDefinition: Sendable, Equatable {
	public let name: String
	public let description: String
	public let parameters: JSONSchemaValue

	public init(name: String, description: String, parameters: JSONSchemaValue) {
		self.name = name
		self.description = description
		self.parameters = parameters
	}
}

extension ToolDefinition: Encodable {
	private enum CodingKeys: String, CodingKey {
		case type
		case function
	}

	private struct FunctionPayload: Encodable {
		let name: String
		let description: String
		let parameters: JSONSchemaValue
	}

	public func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode("function", forKey: .type)
		try container.encode(
			FunctionPayload(name: name, description: description, parameters: parameters),
			forKey: .function
		)
	}
}

/// Constraint types used by `@Guide` to add JSON Schema constraints.
public enum GuideConstraint: Sendable {
	/// Restricts a string property to specific allowed values.
	case anyOf([String])
	/// Restricts an integer property to a range.
	case range(ClosedRange<Int>)
	/// Restricts a number property to a range.
	case doubleRange(ClosedRange<Double>)
	/// Sets exact item count for an array.
	case count(Int)
	/// Sets minimum item count for an array.
	case minimumCount(Int)
	/// Sets maximum item count for an array.
	case maximumCount(Int)
}
