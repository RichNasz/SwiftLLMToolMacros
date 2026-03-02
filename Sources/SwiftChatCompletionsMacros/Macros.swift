/// Generates a JSON Schema for the annotated struct at compile time.
///
/// Attach `@Generable` to a struct to automatically synthesize
/// `Generable`, `Codable`, and `Sendable` conformances with a
/// `static var jsonSchema: JSONSchemaValue` that describes the
/// struct's stored properties as an OpenAI-compatible JSON Schema.
///
/// Use `@Guide` on individual properties to add descriptions and
/// constraints to the generated schema.
///
/// ## Example
///
/// ```swift
/// @Generable
/// struct WeatherQuery {
///     @Guide(description: "The city name")
///     var location: String
///
///     @Guide(description: "Temperature unit", .anyOf(["celsius", "fahrenheit"]))
///     var unit: String?
/// }
/// ```
@attached(member, names: named(jsonSchema))
@attached(extension, conformances: Generable, Codable, Sendable)
public macro Generable() = #externalMacro(
	module: "SwiftChatCompletionsMacrosPlugin",
	type: "GenerableMacro"
)

/// Generates an OpenAI-compatible tool definition for the annotated struct.
///
/// The struct must contain a nested `Arguments` type conforming to `Generable`
/// and a `call(arguments:)` method. The macro synthesizes `Tool` conformance
/// and a `static var toolDefinition: ToolDefinition`.
///
/// ## Example
///
/// ```swift
/// @Tool
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
@attached(extension, conformances: Tool)
@attached(peer)
public macro Tool() = #externalMacro(
	module: "SwiftChatCompletionsMacrosPlugin",
	type: "ToolMacro"
)

/// Adds a description and optional constraints to a property's JSON Schema.
///
/// `@Guide` is a marker macro — it generates no code itself. Instead,
/// `@Generable` reads `@Guide` attributes from sibling properties during
/// its expansion to enrich the generated JSON Schema.
///
/// ## Example
///
/// ```swift
/// @Generable
/// struct Query {
///     @Guide(description: "Search query text")
///     var query: String
///
///     @Guide(description: "Max results", .range(1...100))
///     var limit: Int
/// }
/// ```
@attached(peer)
public macro Guide(description: String, _ constraint: GuideConstraint? = nil) = #externalMacro(
	module: "SwiftChatCompletionsMacrosPlugin",
	type: "GuideMacro"
)
