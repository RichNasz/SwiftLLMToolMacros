# Design Rationale

This document captures **WHY** design decisions were made. It preserves context that guards against regressions — if a future change seems tempting, check here first to understand why the current approach was chosen.

## Why Compile-Time Schema Generation

JSON Schema generation happens entirely at compile time via Swift macros. The generated code constructs `JSONSchemaValue` enum values directly — no runtime reflection, no `Mirror`, no dynamic type inspection. This provides:

- Zero runtime overhead for schema construction
- Compile-time error diagnostics for unsupported types
- Full type safety with no possibility of runtime schema/type mismatches

## Why `@Guide` Is a Marker Macro

`@Guide` is declared as a `PeerMacro` but generates no code. Its attributes are read by `@Generable` during expansion. This avoids expansion ordering conflicts — if `@Guide` generated code that `@Generable` consumed, the compiler would need to guarantee `@Guide` expands first, which Swift macros do not guarantee for sibling declarations.

## Why Struct-Only Restriction

Both `@Generable` and `@Tool` require structs because:

- JSON Schema `"type": "object"` maps cleanly to Swift structs (named properties with fixed types)
- Structs provide value semantics matching JSON's data model
- Classes would introduce inheritance complications not representable in JSON Schema
- Enums require a different schema pattern (`oneOf`/`enum`) not yet supported

## Why OpenAI Function-Calling Format

The `ToolDefinition` type encodes to `{"type":"function","function":{...}}` — the format specified by OpenAI's Chat Completions API. This format has become a de facto standard adopted by Anthropic, Mistral, Groq, and other providers. Targeting it maximizes compatibility across the ecosystem.

## Why FoundationModels API Naming

The macro names (`@Tool`, `@Generable`, `@Guide`) and protocol shapes mirror Apple's FoundationModels framework (introduced in iOS 26 / macOS 26). This naming parity means:

- Developers familiar with FoundationModels can use this library with near-zero learning curve
- Code can be migrated between on-device (FoundationModels) and cloud (OpenAI-compatible) with minimal changes
- The API feels native to the Swift ecosystem rather than being a direct port of OpenAI's Python/JS conventions
