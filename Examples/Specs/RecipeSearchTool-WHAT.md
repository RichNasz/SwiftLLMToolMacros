# Recipe Search Tool -- WHAT Spec

## Purpose

A tool that lets an LLM search a recipe database by query text, dietary restrictions, ingredient filters, and nutrition criteria. Demonstrates every SwiftLLMToolMacros type and constraint category.

## Tool: RecipeSearch

- **Name**: `recipe_search`
- **Description**: Search a recipe database by query, dietary restrictions, and ingredients.

## Arguments

| Property | Type | Required | Description | Constraints |
|---|---|---|---|---|
| query | String | Yes | Search text for recipe names or descriptions | -- |
| dietaryRestrictions | String? | No | Dietary filter | anyOf: vegetarian, vegan, gluten-free, dairy-free |
| maxResults | Int | Yes | Maximum number of recipes to return | range: 1...50 |
| maxCaloriesPerServing | Double? | No | Upper calorie limit per serving | -- |
| includeNutrition | Bool | Yes | Whether to include nutrition info in results | -- |
| ingredients | [String]? | No | Ingredients that must appear in the recipe | minimumCount: 1 |
| nutritionFilter | NutritionInfo? | No | Filter recipes by nutrition criteria | Nested type |

## Nested Type: NutritionInfo

| Property | Type | Required | Description |
|---|---|---|---|
| calories | Int | Yes | Calorie count per serving |
| protein | Double | Yes | Protein in grams |
| isLowSodium | Bool? | No | Whether the recipe qualifies as low-sodium |

## Tool Output

Returns a JSON-formatted list of matching recipes with names, descriptions, and optional nutrition info.

## Acceptance Criteria

- [ ] All arguments map to correct JSON Schema types
- [ ] Optional properties excluded from `required` array
- [ ] `.anyOf` constraint produces `enum` in schema
- [ ] `.range` constraint produces `minimum`/`maximum` in schema
- [ ] `.minimumCount` constraint produces `minItems` in schema
- [ ] Nested `NutritionInfo` appears as inline object schema
- [ ] `toolDefinition` encodes to valid OpenAI function-calling format
- [ ] Tool name derived from struct name as `recipe_search` (PascalCase to snake_case)
- [ ] Doc comment becomes the function description
