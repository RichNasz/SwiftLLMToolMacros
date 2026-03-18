# Design Rationale

This document captures **WHY** design decisions were made. It preserves context that guards against regressions — if a future change seems tempting, check here first to understand why the current approach was chosen.

## Why Compile-Time Schema Generation

JSON Schema generation happens entirely at compile time via Swift macros. The generated code constructs `JSONSchemaValue` enum values directly — no runtime reflection, no `Mirror`, no dynamic type inspection. This provides:

- Zero runtime overhead for schema construction
- Compile-time error diagnostics for unsupported types
- Full type safety with no possibility of runtime schema/type mismatches

## Why `@LLMToolGuide` Is a Marker Macro

`@LLMToolGuide` is declared as a `PeerMacro` but generates no code. Its attributes are read by `@LLMToolArguments` during expansion. This avoids expansion ordering conflicts — if `@LLMToolGuide` generated code that `@LLMToolArguments` consumed, the compiler would need to guarantee `@LLMToolGuide` expands first, which Swift macros do not guarantee for sibling declarations.

## Why Struct-Only Restriction

Both `@LLMToolArguments` and `@LLMTool` require structs because:

- JSON Schema `"type": "object"` maps cleanly to Swift structs (named properties with fixed types)
- Structs provide value semantics matching JSON's data model
- Classes would introduce inheritance complications not representable in JSON Schema
- Enums require a different schema pattern (`oneOf`/`enum`) not yet supported

## Why OpenAI Function-Calling Format

The `ToolDefinition` type encodes to `{"type":"function","function":{...}}` — the format specified by OpenAI's Chat Completions API. This format has become a de facto standard adopted by Anthropic, Mistral, Groq, and other providers. Targeting it maximizes compatibility across the ecosystem.

## Why FoundationModels API Naming

The macros were originally named `@Tool`, `@Generable`, and `@Guide` to mirror Apple's FoundationModels framework (introduced in iOS 26 / macOS 26). They were renamed to `@LLMTool`, `@LLMToolArguments`, and `@LLMToolGuide` to avoid conflicts with Apple's FoundationModels macros while remaining broadly applicable to any LLM API (not just chat completions). The `LLMTool*` prefix is concise, collision-free, and communicates the macros' purpose without tying them to a specific API style. This means:

- Developers can import both FoundationModels and SwiftLLMToolMacros without name conflicts
- The macro names clearly communicate their purpose — generating definitions for LLM tool calling — without overfitting to the OpenAI chat completions naming convention
- The protocol shapes still mirror FoundationModels conventions, so developers familiar with that framework can transfer their knowledge with minimal friction
