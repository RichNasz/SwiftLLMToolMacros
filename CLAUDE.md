# SwiftChatCompletionsMacros

## Project Overview

SwiftChatCompletionsMacros is a Swift Package Manager project that provides compile-time Swift macros (`@ChatCompletionsTool`, `@ChatCompletionsToolArguments`, `@ChatCompletionsToolGuide`) for generating OpenAI-compatible JSON Schema definitions. It is the compile-time companion to SwiftChatCompletionsDSL, with naming designed to avoid conflicts with Apple FoundationModels.

## Commands

- **Build**: `swift build`
- **Test**: `swift test`
- **Test (verbose)**: `swift test --verbose`
- **Clean**: `swift package clean`
- **Generate Xcode project**: `swift package generate-xcodeproj`

## Architecture

### Three-Target Structure

1. **SwiftChatCompletionsMacros** (library target) - Public API that users import
   - `Macros.swift` - `@ChatCompletionsTool`, `@ChatCompletionsToolArguments`, `@ChatCompletionsToolGuide` macro declarations
   - `Protocols.swift` - `ChatCompletionsToolArguments` and `ChatCompletionsTool` protocols
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
- **`@ChatCompletionsToolGuide` is a marker macro**: Generates no code itself. `@ChatCompletionsToolArguments` reads `@ChatCompletionsToolGuide` attributes from sibling properties during expansion.
- **`@ChatCompletionsTool` dispatches by declaration kind**: Handles structs via MemberMacro + ExtensionMacro. PeerMacro is available for future function support.
- **Conflict-free naming**: The `ChatCompletionsTool*` prefix avoids naming collisions with Apple's FoundationModels (`@Tool`, `@Generable`, `@Guide`).

### Type-to-Schema Mapping

| Swift Type | JSON Schema |
|---|---|
| `String` | `{"type": "string"}` |
| `Int` | `{"type": "integer"}` |
| `Double` | `{"type": "number"}` |
| `Bool` | `{"type": "boolean"}` |
| `T?` | Same schema, excluded from `required` |
| `[T]` | `{"type": "array", "items": ...}` |
| Nested `@ChatCompletionsToolArguments` | Delegates to nested type's `jsonSchema` |
| `.null` (JSONSchemaValue) | `{"type": "null"}` |

## Dependencies

- [swift-syntax](https://github.com/swiftlang/swift-syntax) `>= 602.0.0` (for SwiftSyntaxMacros + SwiftCompilerPlugin)

## Requirements

- Swift 6.2+
- macOS 13.0+ / iOS 16.0+

## File Structure

```
Sources/
  SwiftChatCompletionsMacros/       # Public API
    Macros.swift                    # @ChatCompletionsTool, @ChatCompletionsToolArguments, @ChatCompletionsToolGuide declarations
    Protocols.swift                 # ChatCompletionsToolArguments, ChatCompletionsTool protocols
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
Examples/
  BasicUsage.swift                        # Compilable usage examples
  Specs/
    RecipeSearchTool-WHAT.md              # Sample WHAT spec for package consumers
    RecipeSearchTool-HOW.md               # Sample HOW spec for package consumers
Spec/
  README.md                               # Spec index and philosophy
  SwiftChatCompletionsMacros.md           # Core product spec (WHAT + HOW)
  DesignRationale.md                      # Design decisions (WHY)
  DocumentationSpec.md                    # Documentation rules
  ContributingSpec.md                     # Contribution standards
  ProjectStructureSpec.md                 # Directory layout and placement rules
  TestingSpec.md                          # Testing philosophy
docs/
  SpecDrivenDevelopment.md                # SDD workflow guide (WHAT + HOW + Skill harmony)
skills/
  using-swift-chat-completions-macros/
    SKILL.md                              # Agent Skill for AI coding assistants
```

## Claude Code Files

Only the following Claude-related files are tracked in this repository:

- **`CLAUDE.md`** — Project instructions loaded automatically by Claude Code
- **`skills/`** — Agent skills for package consumers and AI coding assistants

The `.claude/` directory (including `settings.local.json` and any other local configuration) is gitignored and must never be committed. It contains local developer permissions and settings that are machine-specific and should not be released.

## Testing Strategy

- **Macro expansion tests** use `assertMacroExpansion` from SwiftSyntaxMacrosTestSupport (XCTest)
- **Runtime type tests** use Swift Testing framework (`@Test`, `#expect`)
- Tests cover: primitive types, optionals, arrays, nested types, `@ChatCompletionsToolGuide` descriptions/constraints, error diagnostics, JSON encoding
