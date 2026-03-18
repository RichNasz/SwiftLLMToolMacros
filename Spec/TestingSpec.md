# Testing Specification

## Testing Frameworks

The project uses two testing frameworks:

### XCTest

Used for macro expansion tests via `assertMacroExpansion` from SwiftSyntaxMacrosTestSupport.

**Why XCTest**: `assertMacroExpansion` is provided by SwiftSyntaxMacrosTestSupport and is built on XCTest. There is no Swift Testing equivalent. All macro expansion verification must use XCTest.

### Swift Testing

Used for runtime type tests via `@Test` and `#expect`.

**Why Swift Testing**: Provides cleaner syntax, better parameterized test support, and is the modern standard for Swift testing. Used for all tests that don't require `assertMacroExpansion`.

## Coverage Tiers

### Tier 1: Critical — Macro Expansion Tests

Every macro must have expansion tests verifying the generated code is syntactically correct and semantically complete.

Required coverage:
- `@ChatCompletionsToolArguments` with each primitive type (`String`, `Int`, `Double`, `Bool`)
- `@ChatCompletionsToolArguments` with optional properties (excluded from `required`)
- `@ChatCompletionsToolArguments` with array properties
- `@ChatCompletionsToolArguments` with nested `@ChatCompletionsToolArguments` types
- `@ChatCompletionsToolGuide` with `description` parameter
- `@ChatCompletionsToolGuide` with each constraint type (`.anyOf`, `.range`, `.doubleRange`, `.count`, `.minimumCount`, `.maximumCount`)
- `@ChatCompletionsTool` struct expansion (name, description, toolDefinition)
- `@ChatCompletionsTool` PascalCase-to-snake_case name conversion
- `@ChatCompletionsTool` doc comment extraction for description
- Error diagnostic when `@ChatCompletionsToolArguments` applied to non-struct
- Error diagnostic when `@ChatCompletionsTool` applied to non-struct

### Tier 2: Important — Runtime Encoding Tests

Verify that `JSONSchemaValue` and `ToolDefinition` encode to correct JSON.

Required coverage:
- Each `JSONSchemaValue` case encodes to correct JSON structure
- `ToolDefinition` encodes to OpenAI-compatible format
- Nested object schemas encode correctly
- Array schemas encode correctly
- Description and constraint parameters appear in encoded output

### Tier 3: Standard — Type Behavior Tests

Verify protocol conformance and type behavior.

Required coverage:
- `JSONSchemaValue` equality (`Equatable`)
- `JSONSchemaValue` construction for all cases
- `ToolOutput` creation and content access
- `GuideConstraint` construction for all cases

## Test Naming Conventions

### XCTest (macro expansion tests)

```swift
func testGenerableWithStringProperty() { }
func testToolPascalCaseConversion() { }
func testGenerableOnNonStructEmitsError() { }
```

Pattern: `test` + macro name + scenario description, camelCase.

### Swift Testing (runtime tests)

```swift
@Test func jsonSchemaStringEncoding() { }
@Test func toolDefinitionEncodesOpenAIFormat() { }
```

Pattern: Descriptive name without `test` prefix, camelCase.

## Commands

```bash
# Run all tests
swift test

# Run tests with verbose output
swift test --verbose

# Run a specific test (XCTest)
swift test --filter SwiftLLMToolMacrosTests.testGenerableWithStringProperty

# Run a specific test (Swift Testing)
swift test --filter RuntimeTypeTests
```

## Future Test Priorities

When adding new features, prioritize test coverage in this order:

1. Macro expansion test for the new feature (Tier 1)
2. Runtime encoding test if the feature affects JSON output (Tier 2)
3. Type behavior test if new types are introduced (Tier 3)

Every PR that adds or modifies macro behavior must include corresponding Tier 1 tests.
