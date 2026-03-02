# Documentation Specification

## README.md

The README should include:

1. **Badges**: Swift version, license, platform
2. **Overview**: One-paragraph description of what the package does
3. **Quick Start**: SPM installation + basic usage example
4. **Supported Types**: Table of Swift-to-JSON-Schema mappings
5. **Guide Constraints**: Examples of all constraint types
6. **Requirements**: Swift version, platform minimums
7. **Contributing**: Link to CONTRIBUTING.md
8. **License**: Apache 2.0

## Examples

### `Examples/BasicUsage.swift`

Must demonstrate:
- `@Generable` struct with `@Guide` descriptions
- `@Tool` struct with nested `Arguments`
- Using `toolDefinition` to encode JSON
- Multiple tools
- Nested `@Generable` types

## CLAUDE.md

Must include:
- Project overview
- Build/test commands
- Architecture (three-target structure)
- Key design decisions
- Type-to-schema mapping table
- Dependency information
- File structure
- Testing strategy
