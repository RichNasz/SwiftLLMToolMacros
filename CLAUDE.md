# SwiftChatCompletionsMacros

## Project Overview

SwiftChatCompletionsMacros is a Swift Package Manager project that provides compile-time Swift macros (`@Tool`, `@Generable`, `@Guide`) for generating OpenAI-compatible JSON Schema definitions. It brings Apple FoundationModels tool-calling style to any OpenAI-compatible `/chat/completions` endpoint.

## Commands

- **Build**: `swift build`
- **Test**: `swift test`
- **Test (verbose)**: `swift test --verbose`
- **Clean**: `swift package clean`
- **Generate Xcode project**: `swift package generate-xcodeproj`

## Architecture

### Three-Target Structure

1. **SwiftChatCompletionsMacros** (library target) - Public API that users import
   - `Macros.swift` - `@Tool`, `@Generable`, `@Guide` macro declarations
   - `Protocols.swift` - `Generable` and `Tool` protocols
   - `Types.swift` - `JSONSchemaValue`, `ToolDefinition`, `ToolOutput`, `GuideConstraint`

2. **SwiftChatCompletionsMacrosPlugin** (macro target) - Compiler plugin
   - `Plugin.swift` - CompilerPlugin entry point
   - `GenerableMacro.swift` - Core schema generation logic
   - `ToolMacro.swift` - Tool definition generation
   - `GuideMacro.swift` - Marker macro (no code generation)

3. **SwiftChatCompletionsMacrosTests** (test target) - Tests
   - XCTest-based macro expansion tests (`assertMacroExpansion`)
   - Swift Testing runtime type tests (`@Test`, `#expect`)

### Key Design Decisions

- **JSON Schema at compile time**: Macros generate `JSONSchemaValue` enum constructors. The enum's `Encodable` conformance handles JSON serialization at runtime. No reflection or mirrors.
- **@Guide is a marker macro**: Generates no code itself. `@Generable` reads `@Guide` attributes from sibling properties during expansion.
- **@Tool dispatches by declaration kind**: Handles structs via MemberMacro + ExtensionMacro. PeerMacro is available for future function support.

### Type-to-Schema Mapping

| Swift Type | JSON Schema |
|---|---|
| `String` | `{"type": "string"}` |
| `Int` | `{"type": "integer"}` |
| `Double` | `{"type": "number"}` |
| `Bool` | `{"type": "boolean"}` |
| `T?` | Same schema, excluded from `required` |
| `[T]` | `{"type": "array", "items": ...}` |
| Nested `@Generable` | Delegates to nested type's `jsonSchema` |

## Dependencies

- [swift-syntax](https://github.com/swiftlang/swift-syntax) `>= 602.0.0` (for SwiftSyntaxMacros + SwiftCompilerPlugin)

## Requirements

- Swift 6.2+
- macOS 13.0+ / iOS 16.0+

## File Structure

```
Sources/
  SwiftChatCompletionsMacros/       # Public API
    Macros.swift                    # @Tool, @Generable, @Guide declarations
    Protocols.swift                 # Generable, Tool protocols
    Types.swift                     # JSONSchemaValue, ToolDefinition, etc.
  SwiftChatCompletionsMacrosPlugin/ # Compiler plugin
    Plugin.swift                    # Entry point
    GenerableMacro.swift            # Schema generation
    ToolMacro.swift                 # Tool definition generation
    GuideMacro.swift                # Marker macro
Tests/
  SwiftChatCompletionsMacrosTests/
    SwiftChatCompletionsMacrosTests.swift  # Macro expansion tests
    RuntimeTypeTests.swift                 # Runtime type tests
```

## Testing Strategy

- **Macro expansion tests** use `assertMacroExpansion` from SwiftSyntaxMacrosTestSupport (XCTest)
- **Runtime type tests** use Swift Testing framework (`@Test`, `#expect`)
- Tests cover: primitive types, optionals, arrays, nested types, `@Guide` descriptions/constraints, error diagnostics, JSON encoding
