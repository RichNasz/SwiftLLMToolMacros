/// A type whose structure can be described as a JSON Schema for use with
/// OpenAI-compatible chat completions endpoints.
///
/// Conformance is synthesized by the `@Generable` macro, which generates
/// the `jsonSchema` property at compile time.
public protocol Generable: Codable, Sendable {
	/// The JSON Schema describing this type's structure.
	static var jsonSchema: JSONSchemaValue { get }
}

/// A callable tool that can be used with OpenAI-compatible chat completions
/// endpoints for function calling.
///
/// Conformance is synthesized by the `@Tool` macro, which generates
/// the `toolDefinition` property at compile time.
public protocol Tool: Sendable {
	/// The arguments type for this tool, which must be `Generable`.
	associatedtype Arguments: Generable

	/// The tool name sent to the LLM.
	static var name: String { get }

	/// A description of what the tool does.
	static var description: String { get }

	/// The OpenAI-compatible tool definition for this tool.
	static var toolDefinition: ToolDefinition { get }

	/// Execute the tool with the given arguments.
	func call(arguments: Arguments) async throws -> ToolOutput
}
