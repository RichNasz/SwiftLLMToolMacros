/// Generates a JSON Schema for the annotated struct at compile time.
///
/// Attach `@LLMToolArguments` to a struct to automatically synthesize
/// `LLMToolArguments`, `Codable`, and `Sendable` conformances with a
/// `static var jsonSchema: JSONSchemaValue` that describes the
/// struct's stored properties as an OpenAI-compatible JSON Schema.
///
/// Use `@LLMToolGuide` on individual properties to add descriptions and
/// constraints to the generated schema.
///
/// ## Example
///
/// ```swift
/// @LLMToolArguments
/// struct WeatherQuery {
///     @LLMToolGuide(description: "The city name")
///     var location: String
///
///     @LLMToolGuide(description: "Temperature unit", .anyOf(["celsius", "fahrenheit"]))
///     var unit: String?
/// }
/// ```
@attached(member, names: named(jsonSchema))
@attached(extension, conformances: LLMToolArguments, Codable, Sendable)
public macro LLMToolArguments() = #externalMacro(
	module: "SwiftLLMToolMacrosPlugin",
	type: "GenerableMacro"
)

/// Generates an OpenAI-compatible tool definition for the annotated struct.
///
/// The struct must contain either a `typealias Arguments` pointing to an
/// `LLMToolArguments`-conforming type, or a nested `struct Arguments` that
/// conforms to `LLMToolArguments`. A `func call(arguments:) async throws -> ToolOutput`
/// method is also required. The macro synthesizes `LLMTool` conformance and a
/// `static var toolDefinition: ToolDefinition`.
///
/// ## Example
///
/// ```swift
/// @LLMTool
/// struct GetWeather {
///     /// Get the current weather for a location.
///     ///
///     /// - Parameter arguments: The weather query arguments.
///     func call(arguments: WeatherQuery) async throws -> ToolOutput {
///         ToolOutput(content: "Sunny, 72°F")
///     }
/// }
/// ```
@attached(member, names: named(toolDefinition), named(name), named(description))
@attached(extension, conformances: LLMTool)
@attached(peer)
public macro LLMTool() = #externalMacro(
	module: "SwiftLLMToolMacrosPlugin",
	type: "ToolMacro"
)

/// Adds a description and optional constraints to a property's JSON Schema.
///
/// `@LLMToolGuide` is a marker macro — it generates no code itself.
/// Instead, `@LLMToolArguments` reads `@LLMToolGuide`
/// attributes from sibling properties during its expansion to enrich the
/// generated JSON Schema.
///
/// ## Example
///
/// ```swift
/// @LLMToolArguments
/// struct Query {
///     @LLMToolGuide(description: "Search query text")
///     var query: String
///
///     @LLMToolGuide(description: "Max results", .range(1...100))
///     var limit: Int
/// }
/// ```
@attached(peer)
public macro LLMToolGuide(description: String, _ constraint: GuideConstraint? = nil) = #externalMacro(
	module: "SwiftLLMToolMacrosPlugin",
	type: "GuideMacro"
)
