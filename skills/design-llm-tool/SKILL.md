---
name: design-llm-tool
description: >
  Step-by-step process for designing and implementing a new LLM tool using
  SwiftLLMToolMacros (@LLMTool, @LLMToolArguments, @LLMToolGuide). Use this
  when translating a natural-language description or spec into correct
  macro-annotated Swift code. Complements the using-swift-llm-tool-macros
  reference skill. Scoped to macro code only -- does not cover DSL integration.
---

# Designing an LLM Tool with SwiftLLMToolMacros

Use this process when asked to implement a new tool from a description, spec, or requirements. Work through the steps in order. Each step produces a decision; collect all decisions before writing the final code.

## Step 1: Derive the Tool Name and Doc Comment

The tool struct name must be PascalCase. The macro auto-derives the `name` sent to the LLM as snake_case.

| Struct name | LLM tool name |
|---|---|
| `GetWeather` | `get_weather` |
| `SearchRecipeDB` | `search_recipe_d_b` |
| `SearchRecipes` | `search_recipes` |

Avoid abbreviations in struct names that produce awkward snake_case (e.g., prefer `SearchRecipes` over `SearchRecipeDB`).

The `///` doc comment on the struct becomes the tool description sent to the LLM. It is required — a missing doc comment produces an empty description string.

```swift
/// Search a recipe database by query and dietary restrictions.
@LLMTool
struct SearchRecipes { ... }
```

## Step 2: List Arguments and Map to Swift Types

Write out every piece of information the tool needs from the LLM. Map each to a Swift type:

| Information | Swift type |
|---|---|
| Free text, names, identifiers | `String` |
| Whole numbers, counts, indices | `Int` |
| Decimals, ratios, measurements | `Double` |
| True/false flags | `Bool` |
| List of uniform items | `[T]` |
| Structured sub-object | Nested `@LLMToolArguments` struct |

Do not use `Float` (use `Double`), `UInt` (use `Int`), or collection types other than `Array`.

## Step 3: Mark Each Argument Required or Optional

Ask: can the LLM reasonably omit this argument and the tool still work?

- **Required** (LLM must provide): use `T` (non-optional)
- **Optional** (LLM may omit): use `T?`

Optional properties are excluded from the JSON Schema `required` array. The LLM sees them as optional. Required properties are included in `required` — the LLM must always provide them.

## Step 4: Choose GuideConstraint for Constrained Arguments

Every argument that benefits from a description gets `@LLMToolGuide(description:)`. Arguments with value constraints get an additional constraint parameter.

| Situation | Constraint |
|---|---|
| String must be one of a fixed set | `.anyOf(["a", "b", "c"])` |
| Int must be within a range | `.range(1...100)` |
| Double must be within a range | `.doubleRange(0.0...1.0)` |
| Array must have exactly N items | `.count(N)` |
| Array must have at least N items | `.minimumCount(N)` |
| Array must have at most N items | `.maximumCount(N)` |
| No constraint, just a description | omit constraint parameter |
| No description or constraint needed | omit `@LLMToolGuide` entirely |

Constraint type must match property type: `.anyOf` only on `String`, `.range` only on `Int`, `.doubleRange` only on `Double`, count constraints only on `[T]`.

```swift
@LLMToolGuide(description: "Temperature unit", .anyOf(["celsius", "fahrenheit"]))
var unit: String?

@LLMToolGuide(description: "Max results", .range(1...50))
var maxResults: Int

@LLMToolGuide(description: "Required ingredients", .minimumCount(1))
var ingredients: [String]?
```

## Step 5: Decide Inline vs External Arguments

**Use inline `struct Arguments`** when this arguments type is used by exactly one tool:

```swift
/// Get the current weather for a location.
@LLMTool
struct GetWeather {
    @LLMToolArguments
    struct Arguments {
        @LLMToolGuide(description: "The city name")
        var location: String

        @LLMToolGuide(description: "Temperature unit", .anyOf(["celsius", "fahrenheit"]))
        var unit: String?
    }

    func call(arguments: Arguments) async throws -> ToolOutput {
        ToolOutput(content: "72F in \(arguments.location)")
    }
}
```

**Use external struct + typealias** when the same arguments type is shared by multiple tools, or when it is independently useful as a Codable type:

```swift
@LLMToolArguments
struct WeatherQuery {
    @LLMToolGuide(description: "The city name")
    var location: String
}

/// Get the current weather for a location.
@LLMTool
struct GetWeather {
    typealias Arguments = WeatherQuery

    func call(arguments: WeatherQuery) async throws -> ToolOutput {
        ToolOutput(content: "72F in \(arguments.location)")
    }
}
```

## Step 6: Extract Nested Types (if needed)

When a group of arguments belongs together as a logical sub-object (e.g., an address, a date range, a filter set), extract them into a separate `@LLMToolArguments` struct. The nested type's schema is inlined as a JSON Schema object.

**Define nested types before the struct that references them** — Swift resolves types top-to-bottom.

```swift
// Defined first
@LLMToolArguments
struct NutritionFilter {
    @LLMToolGuide(description: "Max calories per serving")
    var maxCalories: Int

    @LLMToolGuide(description: "Minimum protein grams")
    var minProtein: Double?
}

// References NutritionFilter -- defined after
@LLMToolArguments
struct RecipeSearchQuery {
    @LLMToolGuide(description: "Search text")
    var query: String

    var nutrition: NutritionFilter?  // Optional nested object
}
```

## Step 7: Assemble the Final Code

With all decisions made, write the code:

1. Nested `@LLMToolArguments` types, in dependency order (deepest first)
2. The Arguments struct (inline or external)
3. The `@LLMTool` struct with `///` doc comment, `typealias Arguments` or nested `struct Arguments`, and `call(arguments:)`

Checklist before finishing:
- [ ] `@LLMTool` struct has a `///` doc comment
- [ ] `call` signature is exactly `func call(arguments: Arguments) async throws -> ToolOutput`
- [ ] Every `@LLMToolArguments` struct is a struct (not class, enum, or actor)
- [ ] Every `@LLMToolGuide` constraint matches the property type
- [ ] Nested types are defined before they are referenced
- [ ] `import SwiftLLMToolMacros` is present in the file

## Complete Example

```swift
import SwiftLLMToolMacros

@LLMToolArguments
struct NutritionFilter {
    @LLMToolGuide(description: "Upper calorie limit per serving")
    var maxCalories: Int

    @LLMToolGuide(description: "Minimum protein in grams")
    var minProtein: Double?
}

/// Search a recipe database by query, dietary restrictions, and ingredients.
@LLMTool
struct SearchRecipes {
    @LLMToolArguments
    struct Arguments {
        @LLMToolGuide(description: "Search text for recipe names or descriptions")
        var query: String

        @LLMToolGuide(description: "Dietary filter", .anyOf(["vegetarian", "vegan", "gluten-free"]))
        var dietaryRestriction: String?

        @LLMToolGuide(description: "Maximum number of results", .range(1...50))
        var maxResults: Int

        @LLMToolGuide(description: "Ingredients that must appear", .minimumCount(1))
        var ingredients: [String]?

        var nutrition: NutritionFilter?
    }

    func call(arguments: Arguments) async throws -> ToolOutput {
        // Implementation
        ToolOutput(content: "Found recipes matching \(arguments.query)")
    }
}
```

## Boundary

This skill covers macro-annotated Swift code only. For wiring the resulting tool into a request pipeline, consult the skill for the DSL you are using:

- **SwiftChatCompletionsDSL** — consult the `using-swift-chat-completions-dsl` skill for OpenAI-compatible chat completions (`/v1/chat/completions`)
- **SwiftOpenResponsesDSL** — consult the `using-swift-open-responses-dsl` skill for the OpenAI Responses API (`/v1/responses`)
