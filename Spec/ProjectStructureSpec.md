# Project Structure Specification

## Directory Layout

```
SwiftChatCompletionsMacros/
├── Package.swift                         # SPM manifest
├── README.md                             # User-facing documentation
├── CLAUDE.md                             # AI assistant context
├── CONTRIBUTING.md                       # Contribution guidelines
├── CODE_OF_CONDUCT.md                    # Contributor Covenant
├── SECURITY.md                           # Vulnerability reporting
├── LICENSE                               # Apache 2.0
├── .github/
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug-report.md                 # Bug report template
│   │   └── feature-request.md            # Feature request template
│   └── pull_request_template.md          # PR checklist
├── Spec/                                    # Source of truth for AI code generation
│   ├── README.md                         # Spec index and philosophy
│   ├── SwiftChatCompletionsMacros.md     # Core product spec (WHAT + HOW)
│   ├── DesignRationale.md                # Design decisions (WHY)
│   ├── DocumentationSpec.md              # Documentation rules
│   ├── ContributingSpec.md               # Contribution standards
│   ├── ProjectStructureSpec.md           # This file
│   └── TestingSpec.md                    # Testing philosophy
├── Sources/
│   ├── SwiftChatCompletionsMacros/       # Public API (library target)
│   │   ├── Macros.swift                  # @Tool, @Generable, @Guide declarations
│   │   ├── Protocols.swift               # Generable, Tool protocols
│   │   └── Types.swift                   # JSONSchemaValue, ToolDefinition, etc.
│   └── SwiftChatCompletionsMacrosPlugin/ # Compiler plugin (macro target)
│       ├── Plugin.swift                  # CompilerPlugin entry point
│       ├── GenerableMacro.swift          # @Generable schema generation
│       ├── ToolMacro.swift               # @Tool definition generation
│       └── GuideMacro.swift              # @Guide marker macro
├── Tests/
│   └── SwiftChatCompletionsMacrosTests/
│       ├── SwiftChatCompletionsMacrosTests.swift  # Macro expansion tests (XCTest)
│       └── RuntimeTypeTests.swift                 # Runtime type tests (Swift Testing)
└── Examples/
    └── BasicUsage.swift                  # Compilable usage examples
```

## Three-Target Architecture

The project uses three SPM targets, following Swift macro conventions established by SE-0382 (Expression Macros) and SE-0389 (Attached Macros):

### 1. SwiftChatCompletionsMacros (library)

The public API that users import. Contains macro declarations, protocols, and types. This target has no dependency on swift-syntax — it is lightweight and compiles quickly for downstream consumers.

**Why separate**: Users should not need to compile swift-syntax into their application. The library target contains only the declarations and runtime types. The macro implementations live in the plugin target, which the compiler loads separately.

### 2. SwiftChatCompletionsMacrosPlugin (macro)

The compiler plugin containing macro implementations. Depends on swift-syntax for AST parsing and code generation. Loaded by the Swift compiler at build time, not linked into user applications.

**Why separate**: SE-0382 requires macro implementations to live in a separate executable target. This also keeps the heavy swift-syntax dependency out of user code.

### 3. SwiftChatCompletionsMacrosTests (test)

Tests for both macro expansion correctness and runtime type behavior. Uses two testing frameworks (see TestingSpec.md for rationale).

## File Placement Rules

| Content | Target | Rationale |
|---|---|---|
| Macro declarations (`@attached(...)`) | Library | Users need these in scope to use macros |
| Protocols (`Generable`, `Tool`) | Library | Users conform to these protocols |
| Runtime types (`JSONSchemaValue`, `ToolDefinition`) | Library | Users create, encode, and pass these types |
| Macro implementations (`MemberMacro`, `ExtensionMacro`) | Plugin | Compiler-loaded, not user-visible |
| AST parsing and code generation | Plugin | Depends on swift-syntax |
| `CompilerPlugin` entry point | Plugin | Required by macro plugin architecture |
| Macro expansion tests | Tests | Verifies generated code |
| Runtime behavior tests | Tests | Verifies encoding, protocol conformance |
