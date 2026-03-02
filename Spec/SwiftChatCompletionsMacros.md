# SwiftChatCompletionsMacros Specification

## WHAT

### Purpose

Generate OpenAI-compatible JSON Schema definitions at compile time using Swift macros, enabling type-safe tool calling for any OpenAI-compatible chat completions endpoint.

### Macros

#### `@Generable`

- **Applies to**: Structs only
- **Role**: `@attached(member)` + `@attached(extension)`
- **Generates**: `static var jsonSchema: JSONSchemaValue` member, plus `Generable`, `Codable`, `Sendable` conformance
- **Reads**: `@Guide` attributes from stored properties to enrich schema
- **Error**: Emits compile-time diagnostic if applied to non-struct

#### `@Tool`

- **Applies to**: Structs only
- **Role**: `@attached(member)` + `@attached(extension)` + `@attached(peer)`
- **Generates**: `static let name: String`, `static let description: String`, `static var toolDefinition: ToolDefinition`, plus `Tool` conformance
- **Reads**: Doc comments from struct declaration for description, struct name for tool name (PascalCase to snake_case)
- **Error**: Emits compile-time diagnostic if applied to non-struct

#### `@Guide`

- **Applies to**: Stored properties
- **Role**: `@attached(peer)` (marker only)
- **Generates**: Nothing
- **Parameters**: `description: String`, optional `GuideConstraint`

### Public Types

#### `JSONSchemaValue` (indirect enum)

```swift
public indirect enum JSONSchemaValue: Sendable, Equatable, Encodable {
    case object(properties: [(String, JSONSchemaValue)], required: [String])
    case array(items: JSONSchemaValue)
    case string(description: String? = nil, enumValues: [String]? = nil)
    case integer(description: String? = nil, minimum: Int? = nil, maximum: Int? = nil)
    case number(description: String? = nil, minimum: Double? = nil, maximum: Double? = nil)
    case boolean(description: String? = nil)
}
```

#### `ToolDefinition` (struct)

Encodes to `{"type":"function","function":{"name":...,"description":...,"parameters":...}}`.

#### `ToolOutput` (struct)

Wraps a `String` content result from a tool call.

#### `GuideConstraint` (enum)

`.anyOf([String])`, `.range(ClosedRange<Int>)`, `.doubleRange(ClosedRange<Double>)`, `.count(Int)`, `.minimumCount(Int)`, `.maximumCount(Int)`

### Protocols

#### `Generable: Codable, Sendable`

Requires `static var jsonSchema: JSONSchemaValue`.

#### `Tool: Sendable`

Requires `associatedtype Arguments: Generable`, `name`, `description`, `toolDefinition`, `call(arguments:)`.

### Supported Swift Types

| Swift Type | JSON Schema |
|---|---|
| `String` | `{"type": "string"}` |
| `Int` | `{"type": "integer"}` |
| `Double` | `{"type": "number"}` |
| `Bool` | `{"type": "boolean"}` |
| `T?` | Same as T, excluded from required |
| `[T]` | `{"type": "array", "items": ...}` |
| Nested `@Generable` | Delegates to nested type's `jsonSchema` |

### Error Diagnostics

- `@Generable` on non-struct: "@Generable can only be applied to structs"
- `@Tool` on non-struct: "@Tool can only be applied to structs"

---

## HOW

### Macro Roles

- `@Generable`: `MemberMacro` (generates `jsonSchema`), `ExtensionMacro` (adds conformances)
- `@Tool`: `MemberMacro` (generates `name`, `description`, `toolDefinition`), `ExtensionMacro` (adds `Tool` conformance), `PeerMacro` (reserved for function mode)
- `@Guide`: `PeerMacro` (marker, returns empty array)

### Type-to-Schema Mapping (in GenerableMacro)

1. Parse stored properties from struct declaration
2. For each property, check type annotation:
   - `String` -> `.string()`
   - `Int` -> `.integer()`
   - `Double` -> `.number()`
   - `Bool` -> `.boolean()`
   - `[T]` -> `.array(items: <recursive>)`
   - Other -> `TypeName.jsonSchema` (nested Generable)
3. Check for `@Guide` attribute on the property's variable declaration
4. Extract `description` string literal and optional constraint
5. Apply description/constraints to the schema expression

### @Guide Reading (in GenerableMacro)

The `@Generable` macro reads `@Guide` from sibling properties during member expansion:
1. Iterate `AttributeListSyntax` on each `VariableDeclSyntax`
2. Find `AttributeSyntax` where `attributeName` is "Guide"
3. Parse `LabeledExprListSyntax` for `description:` and constraint arguments

### PascalCase to snake_case (in ToolMacro)

Iterate characters. Before each uppercase character (except first), insert underscore. Lowercase all.

### Doc Comment Extraction (in ToolMacro)

Read `leadingTrivia` from struct declaration. Extract `.docLineComment` pieces. Take first paragraph (up to empty line or parameter documentation).
