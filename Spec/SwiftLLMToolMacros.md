# SwiftLLMToolMacros Specification

## WHAT

### Purpose

Generate OpenAI-compatible JSON Schema definitions at compile time using Swift macros, enabling type-safe tool calling for any OpenAI-compatible chat completions endpoint.

### Macros

#### `@LLMToolArguments`

- **Applies to**: Structs only
- **Role**: `@attached(member)` + `@attached(extension)`
- **Generates**: `static var jsonSchema: JSONSchemaValue` member, plus `LLMToolArguments`, `Codable`, `Sendable` conformance
- **Reads**: `@LLMToolGuide` attributes from stored properties to enrich schema
- **Error**: Emits compile-time diagnostic if applied to non-struct

#### `@LLMTool`

- **Applies to**: Structs only
- **Role**: `@attached(member)` + `@attached(extension)` + `@attached(peer)`
- **Generates**: `static let name: String`, `static let description: String`, `static var toolDefinition: ToolDefinition`, plus `LLMTool` conformance
- **Reads**: Doc comments from struct declaration for description, struct name for tool name (PascalCase to snake_case)
- **Error**: Emits compile-time diagnostic if applied to non-struct

#### `@LLMToolGuide`

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
    case null
}
```

#### `ToolDefinition` (struct)

Encodes to `{"type":"function","function":{"name":...,"description":...,"parameters":...}}`.

#### `ToolOutput` (struct)

Wraps a `String` content result from a tool call.

#### `GuideConstraint` (enum)

`.anyOf([String])`, `.range(ClosedRange<Int>)`, `.doubleRange(ClosedRange<Double>)`, `.count(Int)`, `.minimumCount(Int)`, `.maximumCount(Int)`

### Protocols

#### `LLMToolArguments: Codable, Sendable`

Requires `static var jsonSchema: JSONSchemaValue`.

#### `LLMTool: Sendable`

Requires `associatedtype Arguments: LLMToolArguments`, `name`, `description`, `toolDefinition`, `call(arguments:)`.

### Supported Swift Types

| Swift Type | JSON Schema |
|---|---|
| `String` | `{"type": "string"}` |
| `Int` | `{"type": "integer"}` |
| `Double` | `{"type": "number"}` |
| `Bool` | `{"type": "boolean"}` |
| `T?` | Same as T, excluded from required |
| `[T]` | `{"type": "array", "items": ...}` |
| Nested `@LLMToolArguments` | Delegates to nested type's `jsonSchema` |
| `.null` (JSONSchemaValue) | `{"type": "null"}` |

### Error Diagnostics

- `@LLMToolArguments` on non-struct: "@LLMToolArguments can only be applied to structs"
- `@LLMTool` on non-struct: "@LLMTool can only be applied to structs"

---

## HOW

This section describes the technical design that guides AI code generation. It is organized by component.

### Compiler Plugin Entry Point

The plugin registers three macro types — `GenerableMacro`, `ToolMacro`, and `GuideMacro` — with the Swift compiler via a `@main` struct conforming to `CompilerPlugin`. The `providingMacros` array is the only connection between macro declarations in the library target and their implementations in the plugin target.

### GenerableMacro

GenerableMacro conforms to two macro protocols:

- **MemberMacro** generates a `static var jsonSchema: JSONSchemaValue` computed property that returns an `.object(properties:required:)` value. This is the core schema generation.
- **ExtensionMacro** generates an extension adding `LLMToolArguments`, `Codable`, and `Sendable` conformance.

Both conformances first validate that the declaration is a struct, emitting a diagnostic and returning empty if not.

#### Stored Property Extraction

The MemberMacro iterates over the struct's `memberBlock.members`, looking for `VariableDeclSyntax` nodes with `var` or `let` binding specifiers. For each binding, it checks whether an `accessorBlock` is present — if so, the property is computed and is skipped. Only bindings with an `IdentifierPatternSyntax` pattern and a `typeAnnotation` are collected as stored properties.

#### Optional Detection

Optionals are detected in two syntax forms:

1. **Sugar syntax**: `T?` parses as `OptionalTypeSyntax`. The wrapped type is extracted via `.wrappedType`.
2. **Generic syntax**: `Optional<T>` parses as `IdentifierTypeSyntax` with name `"Optional"` and a `genericArgumentClause`. The first generic argument is the wrapped type.

Optional properties are excluded from the `required` array but still appear in `properties`.

#### Guide Attribute Reading

For each stored property's `VariableDeclSyntax`, the macro walks the `attributes` list looking for an `AttributeSyntax` whose `attributeName` is an `IdentifierTypeSyntax` with name `"LLMToolGuide"`. When found, it parses the labeled argument list:

- An argument labeled `"description"` with a `StringLiteralExprSyntax` value provides the schema description.
- An unlabeled argument (or one labeled `"_"`) is parsed as a constraint.

Constraint parsing examines `FunctionCallExprSyntax` nodes, matching the callee's suffix against known constraint names (`anyOf`, `range`, `doubleRange`, `count`, `minimumCount`, `maximumCount`). For `anyOf`, it extracts string literals from an `ArrayExprSyntax`. For `range` and `doubleRange`, a shared `extractRangeBounds` helper extracts the two bounds, handling both `SequenceExprSyntax` (three elements: left bound, operator, right bound) and `InfixOperatorExprSyntax` (left/right operands) defensively, since swift-syntax may produce either form depending on operator folding.

#### Type-to-Schema Mapping

The mapping from Swift type names to schema expressions follows a decision table:

| Type Name | Schema Expression |
|---|---|
| `"String"` | `.string()` with optional description and enumValues from `.anyOf` constraint |
| `"Int"` | `.integer()` with optional description and min/max from `.range` constraint |
| `"Double"` | `.number()` with optional description and min/max from `.doubleRange` constraint |
| `"Bool"` | `.boolean()` with optional description |
| `"[T]"` (starts with `[`, ends with `]`) | `.array(items: <recursive mapping of T>)` |
| Any other type name | `TypeName.jsonSchema` — delegates to the nested LLMToolArguments type's static property |

#### Generated Output Shape

The MemberMacro produces a single computed property:

```
public static var jsonSchema: JSONSchemaValue {
    .object(
        properties: [("propName", <schema>), ...],
        required: ["nonOptionalProp", ...]
    )
}
```

The ExtensionMacro produces:

```
extension TypeName: LLMToolArguments, Codable, Sendable {}
```

### ToolMacro

ToolMacro conforms to three macro protocols:

- **MemberMacro** generates `name`, `description`, and `toolDefinition` static members.
- **ExtensionMacro** generates an extension adding `LLMTool` conformance.
- **PeerMacro** is available for future free-function support but currently returns empty.

#### Name Derivation

The tool name is derived from the struct name by converting PascalCase to snake_case. The algorithm iterates character by character: each uppercase character (except the first) is preceded by an underscore, then lowercased.

#### Doc Comment Extraction

The tool description is extracted from the struct's `leadingTrivia`. Two doc comment formats are handled:

- **Line comments** (`/// text`): The `"/// "` prefix (or `"///"` without space) is stripped.
- **Block comments** (`/** text */`): The `"/**"` prefix and `"*/"` suffix are stripped, then whitespace is trimmed.

The extracted lines form a description up to the first empty line or the first line starting with `"- Parameter"` or `"- Returns"` — these structured doc comment sections are not part of the tool description. Multiple description lines are joined with spaces.

If no doc comment is found, the description defaults to `"No description provided."`.

#### Arguments Resolution

The `toolDefinition` generation needs to know which type provides `jsonSchema` for the tool's parameters. This follows a fallback chain:

1. **Nested type first**: Look for a type named `"Arguments"` nested inside the struct (struct, enum, or typealias).
2. **Call method parameter**: If no nested Arguments type exists, look for a method named `"call"` and extract the type annotation of its `arguments:` parameter.

If a nested Arguments type is found, the generated code references `Arguments.jsonSchema`. If resolved via the call method parameter, it references `ParameterTypeName.jsonSchema`.

#### String Escaping

Doc comment text may contain characters that are invalid inside Swift string literals. Before embedding the description in generated code, backslashes are escaped to `\\`, double quotes to `\"`, and newlines are replaced with spaces.

#### Generated Output Shape

The MemberMacro produces up to three members:

```
public static let name: String = "snake_case_name"
public static let description: String = "Extracted doc comment text"
public static var toolDefinition: ToolDefinition {
    ToolDefinition(
        name: name,
        description: description,
        parameters: Arguments.jsonSchema
    )
}
```

The ExtensionMacro produces:

```
extension TypeName: LLMTool {}
```

### GuideMacro

GuideMacro conforms to `PeerMacro` and returns an empty array from its expansion method. It is a marker macro — it generates no code. Its sole purpose is to be readable by `@LLMToolArguments` during sibling property inspection. See [DesignRationale.md](DesignRationale.md) for why this pattern is used.

### Types Encoding Design

#### JSONSchemaValue Encoding

Each case of `JSONSchemaValue` encodes to a JSON object matching the OpenAI JSON Schema format. The encoding uses a `singleValueContainer` and builds dictionaries with `AnyCodable` wrappers. Each case writes a `"type"` key, then case-specific keys (`"properties"`, `"required"`, `"items"`, `"description"`, `"enum"`, `"minimum"`, `"maximum"`).

The `.object` case additionally writes `"additionalProperties": false`, as required by OpenAI's strict mode.

#### Heterogeneous Dictionary Encoding

Swift's `Encodable` cannot directly encode `[String: Any]` dictionaries. The `AnyCodable` struct solves this by wrapping any `Encodable & Sendable` value in a closure-based type-erased container. Each `AnyCodable` stores a `@Sendable` encoding closure captured at init time, which is invoked during `encode(to:)`.

#### Object Equality

`JSONSchemaValue` uses a custom `Equatable` implementation because the `.object` case stores properties as `[(String, JSONSchemaValue)]` — a tuple array, which does not automatically conform to `Equatable`. The custom `==` compares property arrays element-by-element (both key and value) and checks `required` arrays for equality.

#### ToolDefinition Nested Wrapper

`ToolDefinition` encodes to the OpenAI function-calling wrapper format using a private `FunctionPayload` struct and a `CodingKeys` enum. The outer level writes `"type": "function"` and nests a `"function"` key containing the actual name, description, and parameters. This two-level encoding matches the format that OpenAI-compatible APIs expect.

### Edge Cases

- **Computed property skipping**: Properties with an `accessorBlock` in any binding are skipped during extraction. Only properties with a type annotation and no accessors are treated as stored properties.
- **Two optional syntax forms**: Both `String?` and `Optional<String>` must be recognized to correctly determine the required array.
- **Line vs block doc comments**: Both `///` line comments and `/** */` block comments are collected and handled uniformly after prefix/suffix stripping.
- **Parameter doc stopping**: Description extraction stops at `"- Parameter"` or `"- Returns"` lines to avoid including structured documentation in the tool description.
- **String literal escaping**: Backslashes, double quotes, and newlines in doc comments must be escaped before embedding in generated string literals.
- **Default description fallback**: If no doc comment is present on a `@LLMTool` struct, the description falls back to `"No description provided."` rather than failing.
