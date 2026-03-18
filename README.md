# SwiftLLMToolMacros

[![Swift 6.2](https://img.shields.io/badge/Swift-6.2-orange.svg)](https://swift.org)
[![Xcode CLI](https://img.shields.io/badge/Xcode%20CLI-16+-blue.svg)](https://developer.apple.com/xcode/)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-macOS%2013%20%7C%20iOS%2016-lightgrey.svg)](Package.swift)
[![Built with Claude Code](https://img.shields.io/badge/Built%20with-Claude%20Code-blueviolet?logo=claude)](https://claude.ai/code)

Swift macros that generate OpenAI-compatible JSON Schema at compile time -- zero runtime overhead, zero naming conflicts with Apple FoundationModels, fully type-safe.

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [How It Works](#how-it-works)
- [Supported Types](#supported-types)
- [@LLMToolGuide Constraints](#llmtoolguide-constraints)
- [Apple FoundationModels Compatibility](#apple-foundationmodels-compatibility)
- [Designed for SwiftChatCompletionsDSL and SwiftOpenResponsesDSL](#designed-for-swiftchatcompletionsdsl-and-swiftopenresponsesdsl)
- [Requirements](#requirements)
- [Contributing](#contributing)
- [Agent Skill](#agent-skill)
- [Attribution](#attribution)
- [License](#license)

## Overview

SwiftLLMToolMacros provides three macros for defining OpenAI-compatible tool definitions at compile time:

- **`@LLMToolArguments`** -- Generates a JSON Schema for a struct's properties
- **`@LLMTool`** -- Generates an OpenAI-compatible tool definition
- **`@LLMToolGuide`** -- Adds descriptions and constraints to property schemas

## Quick Start

### Installation

Add SwiftLLMToolMacros to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/RichNasz/SwiftLLMToolMacros.git", from: "0.1.0")
]
```

Then add it as a dependency to your target:

```swift
.target(
    name: "YourTarget",
    dependencies: ["SwiftLLMToolMacros"]
)
```

### Basic Usage

```swift
import SwiftLLMToolMacros

// Define a structured type for tool arguments
@LLMToolArguments
struct WeatherQuery {
    @LLMToolGuide(description: "The city to get weather for")
    var location: String

    @LLMToolGuide(description: "Temperature unit", .anyOf(["celsius", "fahrenheit"]))
    var unit: String?
}

// Define a tool
/// Get the current weather for a location.
@LLMTool
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

## How It Works

`@LLMToolArguments` expands your struct at compile time, generating a `jsonSchema` property and protocol conformances. No runtime reflection or mirrors.

**You write:**

```swift
@LLMToolArguments
struct WeatherQuery {
    @LLMToolGuide(description: "The city name")
    var location: String
    var unit: String?
}
```

**The macro generates:**

```swift
struct WeatherQuery {
    var location: String
    var unit: String?

    public static var jsonSchema: JSONSchemaValue {
        .object(
            properties: [
                ("location", .string(description: "The city name")),
                ("unit", .string())
            ],
            required: ["location"]
        )
    }
}

extension WeatherQuery: LLMToolArguments, Codable, Sendable {}
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
| Nested `@LLMToolArguments` | `{"type": "object", ...}` | Yes |
| `.null` (JSONSchemaValue) | `{"type": "null"}` | Yes |

## `@LLMToolGuide` Constraints

```swift
@LLMToolArguments
struct SearchQuery {
    @LLMToolGuide(description: "Search text")
    var query: String

    @LLMToolGuide(description: "Max results", .range(1...100))
    var limit: Int

    @LLMToolGuide(description: "Sort order", .anyOf(["relevance", "date", "popularity"]))
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

## Apple FoundationModels Compatibility

Apple's [FoundationModels](https://developer.apple.com/documentation/FoundationModels) framework provides macros for on-device inference: [`@Generable`](https://developer.apple.com/documentation/foundationmodels/generable) for structured output, [`@Guide`](https://developer.apple.com/documentation/foundationmodels/guide(description:)) for property descriptions and constraints, and [`@Tool`](https://developer.apple.com/documentation/foundationmodels/tool) for [tool calling](https://developer.apple.com/documentation/foundationmodels/expanding-generation-with-tool-calling).

SwiftLLMToolMacros follows the same macro-driven pattern -- annotate structs, get schema generation at compile time -- but targets **cloud-based APIs** (OpenAI, Anthropic, Mistral, Groq) instead of Apple's on-device model. The two frameworks serve different inference targets but share the same philosophy: define your types once, let the compiler generate the schema.

| | SwiftLLMToolMacros | Apple FoundationModels |
|---|---|---|
| **Schema macro** | `@LLMToolArguments` | [`@Generable`](https://developer.apple.com/documentation/foundationmodels/generable) |
| **Constraint macro** | `@LLMToolGuide` | [`@Guide`](https://developer.apple.com/documentation/foundationmodels/guide(description:)) |
| **Tool macro** | `@LLMTool` | [`@Tool`](https://developer.apple.com/documentation/foundationmodels/tool) |
| **Output format** | OpenAI-compatible JSON Schema | Apple on-device constrained decoding |
| **Inference target** | Cloud APIs (OpenAI, Anthropic, etc.) | On-device Apple Intelligence |
| **Platform** | macOS 13+ / iOS 16+ | macOS 26+ / iOS 26+ |

The `LLMTool*` prefix is deliberately chosen so you can import both packages in the same project with zero naming collisions. This means you can support both on-device and cloud-based inference from the same codebase.

## Designed for SwiftChatCompletionsDSL and SwiftOpenResponsesDSL

SwiftLLMToolMacros is the compile-time companion to [SwiftChatCompletionsDSL](https://github.com/RichNasz/SwiftChatCompletionsDSL) and [SwiftOpenResponsesDSL](https://github.com/RichNasz/SwiftOpenResponsesDSL). Use either DSL to make requests and this package to define your tools -- they work together seamlessly.

## Requirements

- Swift 6.2+
- macOS 13.0+ / iOS 16.0+

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Agent Skill

This project includes an [Agent Skill](https://agentskills.io) at [`skills/using-swift-chat-completions-macros/SKILL.md`](skills/using-swift-chat-completions-macros/SKILL.md) that gives AI coding assistants package-specific context for using the macros correctly.

**This is entirely optional.** Agent Skills are only useful if you use an AI coding agent that implements the [agentskills.io](https://agentskills.io) specification (Claude Code, Cursor, Gemini CLI, etc.). The macros work the same with or without the skill installed.

### Installing the Skill

Adding SwiftLLMToolMacros as an SPM dependency does **not** make the skill available to your agent -- SPM downloads sources into `.build/checkouts/`, which agents don't scan. To install the skill, copy the folder into a location your agent is configured to discover:

```bash
cp -r .build/checkouts/SwiftLLMToolMacros/skills/using-swift-chat-completions-macros \
      skills/using-swift-chat-completions-macros
```

This places the skill in your project's `skills/` directory, where compatible agents will find it automatically.

### Spec-Driven Development

If you use AI coding agents, you can pair the Agent Skill with WHAT and HOW specs to define tools before generating code. See the [Spec-Driven Development Guide](docs/SpecDrivenDevelopment.md) for the workflow and [`Examples/Specs/`](Examples/Specs/) for sample specs you can use as templates.

## Attribution

SwiftLLMToolMacros is created and maintained by [RichNasz](https://github.com/RichNasz). Code is generated with [Claude Code](https://claude.ai/code) by Anthropic. All code is human-reviewed and human-directed.

## License

SwiftLLMToolMacros is available under the Apache License 2.0. See [LICENSE](LICENSE) for details.
