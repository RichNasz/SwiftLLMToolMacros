---
name: using-swift-llm-tool-macros
description: >
  Helps the agent use the SwiftLLMToolMacros Swift package to define
  OpenAI-compatible tool definitions at compile time using @LLMTool,
  @LLMToolArguments, and @LLMToolGuide macros. Useful when
  building function calling, JSON Schema generation, or chat completions tooling
  in Swift. The macro names avoid conflicts with Apple FoundationModels.
---

# Using SwiftLLMToolMacros

## Installation

Add to `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/RichNasz/SwiftLLMToolMacros.git", from: "0.1.0")
]
```

Add the dependency to your target:

```swift
.target(name: "YourTarget", dependencies: ["SwiftLLMToolMacros"])
```

Import in source files:

```swift
import SwiftLLMToolMacros
```

## Macros

### @LLMToolArguments

Attach to a **struct** to generate a `static var jsonSchema: JSONSchemaValue` that describes stored properties as an OpenAI-compatible JSON Schema. Also synthesizes `LLMToolArguments`, `Codable`, and `Sendable` conformances via extension.

```swift
@LLMToolArguments
struct WeatherQuery {
    @LLMToolGuide(description: "The city name")
    var location: String
    var unit: String?
}
```

Generates:

```swift
public static var jsonSchema: JSONSchemaValue {
    .object(
        properties: [
            ("location", .string(description: "The city name")),
            ("unit", .string())
        ],
        required: ["location"]  // optionals excluded
    )
}
extension WeatherQuery: LLMToolArguments, Codable, Sendable {}
```

### @LLMTool

Attach to a **struct** that has:

1. A `typealias Arguments` pointing to a `LLMToolArguments`-conforming type
2. A `func call(arguments:) async throws -> ToolOutput` method
3. A **doc comment** on the struct (becomes the tool description)

Generates `static var toolDefinition: ToolDefinition`, `static var name: String`, `static var description: String`, and `LLMTool` conformance.

```swift
/// Get the current weather for a location.
@LLMTool
struct GetWeather {
    typealias Arguments = WeatherQuery

    func call(arguments: WeatherQuery) async throws -> ToolOutput {
        ToolOutput(content: "Sunny, 72F")
    }
}
```

The `name` is auto-derived as snake_case from the struct name (`GetWeather` -> `"get_weather"`).

### @LLMToolGuide

A **marker macro** -- generates no code itself. Attach to stored properties inside a `@LLMToolArguments` struct to add a description and optional constraint to that property's JSON Schema entry.

```swift
@LLMToolGuide(description: "Search text")
var query: String

@LLMToolGuide(description: "Max results", .range(1...100))
var limit: Int
```

Signature: `@LLMToolGuide(description: String, _ constraint: GuideConstraint? = nil)`

## Type-to-Schema Mapping

| Swift Type | JSON Schema | In `required`? |
|---|---|---|
| `String` | `{"type": "string"}` | Yes |
| `Int` | `{"type": "integer"}` | Yes |
| `Double` | `{"type": "number"}` | Yes |
| `Bool` | `{"type": "boolean"}` | Yes |
| `T?` | Same schema as `T` | No |
| `[T]` | `{"type": "array", "items": ...}` | Yes |
| Nested `@LLMToolArguments` | Delegates to nested type's `jsonSchema` | Yes |
| `.null` (JSONSchemaValue) | `{"type": "null"}` | Yes |

## GuideConstraint Reference

| Constraint | Applies To | Schema Effect | Example |
|---|---|---|---|
| `.anyOf([String])` | `String` | `"enum": [...]` | `.anyOf(["celsius", "fahrenheit"])` |
| `.range(ClosedRange<Int>)` | `Int` | `"minimum"`, `"maximum"` | `.range(1...100)` |
| `.doubleRange(ClosedRange<Double>)` | `Double` | `"minimum"`, `"maximum"` | `.doubleRange(0.0...1.0)` |
| `.count(Int)` | `[T]` | `"minItems"`, `"maxItems"` (same value) | `.count(3)` |
| `.minimumCount(Int)` | `[T]` | `"minItems"` | `.minimumCount(1)` |
| `.maximumCount(Int)` | `[T]` | `"maxItems"` | `.maximumCount(10)` |

## Patterns

### Inline Arguments

Define `Arguments` as a nested struct inside the tool:

```swift
/// Search the database.
@LLMTool
struct SearchDB {
    @LLMToolArguments
    struct Arguments: LLMToolArguments {
        @LLMToolGuide(description: "Search query")
        var query: String
    }

    func call(arguments: Arguments) async throws -> ToolOutput {
        ToolOutput(content: "results")
    }
}
```

### External Arguments with Typealias

Define `Arguments` separately and reference via typealias:

```swift
@LLMToolArguments
struct SearchQuery {
    @LLMToolGuide(description: "Search query")
    var query: String
}

/// Search the database.
@LLMTool
struct SearchDB {
    typealias Arguments = SearchQuery

    func call(arguments: SearchQuery) async throws -> ToolOutput {
        ToolOutput(content: "results")
    }
}
```

### Nested Types

`@LLMToolArguments` structs can nest inside each other. The nested type's `jsonSchema` is inlined as an object schema:

```swift
@LLMToolArguments
struct Address {
    @LLMToolGuide(description: "Street address")
    var street: String
    @LLMToolGuide(description: "City name")
    var city: String
}

@LLMToolArguments
struct Person {
    @LLMToolGuide(description: "Full name")
    var name: String
    var address: Address  // nested object schema
}
```

## Protocols

### LLMToolArguments

```swift
public protocol LLMToolArguments: Codable, Sendable {
    static var jsonSchema: JSONSchemaValue { get }
}
```

### LLMTool

```swift
public protocol LLMTool: Sendable {
    associatedtype Arguments: LLMToolArguments
    static var name: String { get }
    static var description: String { get }
    static var toolDefinition: ToolDefinition { get }
    func call(arguments: Arguments) async throws -> ToolOutput
}
```

## Using toolDefinition

`ToolDefinition` is `Encodable` and produces the OpenAI `{"type":"function","function":{...}}` format:

```swift
let definition = GetWeather.toolDefinition
let data = try JSONEncoder().encode(definition)
let json = String(data: data, encoding: .utf8)!
```

To encode an array of tools:

```swift
let tools = [GetWeather.toolDefinition, SearchDB.toolDefinition]
let data = try JSONEncoder().encode(tools)
```

## Common Pitfalls

1. **Struct-only**: `@LLMToolArguments` and `@LLMTool` only work on structs. Applying them to classes, enums, or actors produces a compile error.

2. **Arguments resolution**: `@LLMTool` requires either a `typealias Arguments = SomeType` or a nested `struct Arguments` that conforms to `LLMToolArguments`.

3. **call signature**: The `call` method must be `func call(arguments:) async throws -> ToolOutput` with the parameter label `arguments`.

4. **Constraint type matching**: Match `GuideConstraint` to the property type -- `.anyOf` for `String`, `.range` for `Int`, `.doubleRange` for `Double`, `.count`/`.minimumCount`/`.maximumCount` for arrays.

5. **FoundationModels coexistence**: These macros are named `@LLMTool*` specifically to avoid conflicts with Apple FoundationModels' `@Tool`, `@Generable`, `@Guide`. Both packages can be imported in the same file.

6. **Optional handling**: Optional properties (`T?`) get the same schema as `T` but are excluded from the `required` array. There is no nullable schema wrapper.

7. **Doc comment required for tools**: `@LLMTool` extracts the struct's `///` doc comment as the tool description. Missing doc comments produce an empty description string.
