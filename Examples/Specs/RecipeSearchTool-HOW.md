# Recipe Search Tool -- HOW Spec

## Implementation Target

A single Swift file (`RecipeSearchTool.swift`) using SwiftLLMToolMacros.

## Dependencies

```swift
import SwiftLLMToolMacros
```

## Component Design

### 1. NutritionInfo Arguments Struct

Define this struct **before** `RecipeSearchQuery` since it is referenced as a nested type.

- Annotate with `@LLMToolArguments`
- Properties with `@LLMToolGuide(description:)`:
  - `calories: Int` -- "Calorie count per serving"
  - `protein: Double` -- "Protein in grams"
  - `isLowSodium: Bool?` -- "Whether the recipe qualifies as low-sodium"

### 2. RecipeSearchQuery Arguments Struct

- Annotate with `@LLMToolArguments`
- Properties with `@LLMToolGuide`:
  - `query: String` -- description: "Search text for recipe names or descriptions"
  - `dietaryRestrictions: String?` -- description + `.anyOf(["vegetarian", "vegan", "gluten-free", "dairy-free"])`
  - `maxResults: Int` -- description + `.range(1...50)`
  - `maxCaloriesPerServing: Double?` -- description: "Upper calorie limit per serving"
  - `includeNutrition: Bool` -- description: "Whether to include nutrition info in results"
  - `ingredients: [String]?` -- description + `.minimumCount(1)`
  - `nutritionFilter: NutritionInfo?` -- description: "Filter recipes by nutrition criteria" (nested type, no constraint)

### 3. RecipeSearch Tool Struct

- Annotate with `@LLMTool`
- Doc comment: `/// Search a recipe database by query, dietary restrictions, and ingredients.`
- `typealias Arguments = RecipeSearchQuery`
- `func call(arguments: RecipeSearchQuery) async throws -> ToolOutput`
  - Stub implementation returning `ToolOutput(content: "...")`

## Expected Output

Encoding `RecipeSearch.toolDefinition` with `JSONEncoder` produces:

```json
{
  "type": "function",
  "function": {
    "name": "recipe_search",
    "description": "Search a recipe database by query, dietary restrictions, and ingredients.",
    "parameters": {
      "type": "object",
      "properties": {
        "query": { "type": "string", "description": "Search text for recipe names or descriptions" },
        "dietaryRestrictions": { "type": "string", "description": "Dietary filter", "enum": ["vegetarian", "vegan", "gluten-free", "dairy-free"] },
        "maxResults": { "type": "integer", "description": "Maximum number of recipes to return", "minimum": 1, "maximum": 50 },
        "maxCaloriesPerServing": { "type": "number", "description": "Upper calorie limit per serving" },
        "includeNutrition": { "type": "boolean", "description": "Whether to include nutrition info in results" },
        "ingredients": { "type": "array", "items": { "type": "string" }, "description": "Ingredients that must appear in the recipe", "minItems": 1 },
        "nutritionFilter": { "type": "object", "properties": { "calories": { "type": "integer", "description": "Calorie count per serving" }, "protein": { "type": "number", "description": "Protein in grams" }, "isLowSodium": { "type": "boolean", "description": "Whether the recipe qualifies as low-sodium" } }, "required": ["calories", "protein"], "additionalProperties": false }
      },
      "required": ["query", "maxResults", "includeNutrition"],
      "additionalProperties": false
    }
  }
}
```

## Integration Notes

- Encode `RecipeSearch.toolDefinition` alongside other tools for the `tools` array in a chat completions request
- Decode incoming arguments JSON: `JSONDecoder().decode(RecipeSearchQuery.self, from: data)`
