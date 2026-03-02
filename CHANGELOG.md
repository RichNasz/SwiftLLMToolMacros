# Changelog

All notable changes to this project will be documented in this file.

## [0.1.0] - 2026-03-02

### Added
- `@ChatCompletionsTool` macro for generating OpenAI-compatible tool definitions
- `@ChatCompletionsToolArguments` macro for generating JSON Schema from struct properties
- `@ChatCompletionsToolGuide` marker macro for adding descriptions and constraints
- `JSONSchemaValue` enum with compile-time schema construction
- `ToolDefinition` struct encoding to OpenAI function-calling format
- `ToolOutput` and `GuideConstraint` supporting types
- Support for String, Int, Double, Bool, Optional, Array, and nested types
- Comprehensive macro expansion and runtime encoding tests

