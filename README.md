# SwiftChatCompletionsMacros

[![Swift 6.2](https://img.shields.io/badge/Swift-6.2-orange.svg)](https://swift.org)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-macOS%2013%20%7C%20iOS%2016-lightgrey.svg)](Package.swift)

Swift macros that bring Apple FoundationModels tool-calling style (`@Tool`, `@Generable`, `@Guide`) to any OpenAI-compatible `/chat/completions` endpoint. Generates OpenAI-compatible JSON Schema at compile time -- zero runtime overhead, excellent diagnostics, fully type-safe.

## Overview

SwiftChatCompletionsMacros provides three macros that generate OpenAI-compatible tool definitions at compile time:

- **`@Generable`** -- Generates a JSON Schema for a struct's properties
- **`@Tool`** -- Generates an OpenAI-compatible tool definition
- **`@Guide`** -- Adds descriptions and constraints to property schemas

## Quick Start

### Installation

Add SwiftChatCompletionsMacros to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/rnaszcyniec/SwiftChatCompletionsMacros.git", from: "0.1.0")
]
```

Then add it as a dependency to your target:

```swift
.target(
    name: "YourTarget",
    dependencies: ["SwiftChatCompletionsMacros"]
)
```

### Basic Usage

```swift
import SwiftChatCompletionsMacros

// Define a structured type for tool arguments
@Generable
struct WeatherQuery {
    @Guide(description: "The city to get weather for")
    var location: String

    @Guide(description: "Temperature unit", .anyOf(["celsius", "fahrenheit"]))
    var unit: String?
}

// Define a tool
/// Get the current weather for a location.
@Tool
struct GetWeather {
    typealias Arguments = WeatherQuery

    func call(arguments: WeatherQuery) async throws -> ToolOutput {
        // Your implementation here
        ToolOutput(content: "Sunny, 72F in \(arguments.location)")
    }
}

// Use the generated tool definition
let definition = GetWeather.toolDefinition
let jsonData = try JSONEncoder().encode(definition)
// Produces: {"type":"function","function":{"name":"get_weather","description":"Get the current weather for a location.","parameters":{"type":"object","properties":{"location":{"type":"string","description":"The city to get weather for"},"unit":{"type":"string","description":"Temperature unit","enum":["celsius","fahrenheit"]}},"required":["location"],"additionalProperties":false}}}
```

## Supported Types

| Swift Type | JSON Schema | Required? |
|---|---|---|
| `String` | `{"type": "string"}` | Yes |
| `Int` | `{"type": "integer"}` | Yes |
| `Double` | `{"type": "number"}` | Yes |
| `Bool` | `{"type": "boolean"}` | Yes |
| `T?` | Same as `T` | No |
| `[T]` | `{"type": "array", "items": ...}` | Yes |
| Nested `@Generable` | `{"type": "object", ...}` | Yes |

## `@Guide` Constraints

```swift
@Generable
struct SearchQuery {
    @Guide(description: "Search text")
    var query: String

    @Guide(description: "Max results", .range(1...100))
    var limit: Int

    @Guide(description: "Sort order", .anyOf(["relevance", "date", "popularity"]))
    var sortBy: String?
}
```

Available constraints:
- `.anyOf([String])` -- Restricts to specific string values
- `.range(ClosedRange<Int>)` -- Integer range constraint
- `.doubleRange(ClosedRange<Double>)` -- Double range constraint
- `.count(Int)` -- Exact array item count
- `.minimumCount(Int)` -- Minimum array item count
- `.maximumCount(Int)` -- Maximum array item count

## Requirements

- Swift 6.2+
- macOS 13.0+ / iOS 16.0+

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

SwiftChatCompletionsMacros is available under the Apache License 2.0. See [LICENSE](LICENSE) for details.
