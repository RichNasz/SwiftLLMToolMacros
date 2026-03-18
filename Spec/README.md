# Spec Directory

This directory contains the specification files for SwiftLLMToolMacros. Specs are the **source of truth for AI code generation**. When the product needs to change, specs change first, then AI generates the corresponding code.

## Spec Types

Specs are organized into three categories:

- **WHAT** — Defines desired functionality, product surface, and behavior from the user's perspective. Human-maintained. Does not prescribe implementation.
- **HOW** — Technical design decisions that guide AI code generation. Written as prose specifications covering architecture, data flows, component responsibilities, and edge cases.
- **WHY** — Design rationale. Explains why decisions were made. Guards against regressions by preserving context that would otherwise be lost.

## Spec Files

| File | Type | Purpose |
|---|---|---|
| [SwiftLLMToolMacros.md](SwiftLLMToolMacros.md) | WHAT + HOW | Core product specification and technical design |
| [DesignRationale.md](DesignRationale.md) | WHY | Design rationale and decision history |
| [DocumentationSpec.md](DocumentationSpec.md) | WHAT | Rules for README, CLAUDE.md, examples, and community files |
| [ContributingSpec.md](ContributingSpec.md) | WHAT | Contribution standards, commit conventions, PR process, Code of Conduct |
| [ProjectStructureSpec.md](ProjectStructureSpec.md) | WHAT | Directory layout, target architecture, file placement rules |
| [TestingSpec.md](TestingSpec.md) | WHAT | Testing philosophy, coverage tiers, framework choices, naming conventions |

## Workflow

1. **Spec changes first**: When functionality needs to change, update the relevant spec files before modifying code.
2. **AI generates code**: AI reads specs to understand what to build and how to build it, then generates the implementation.
3. **Tests verify**: Run `swift build && swift test` to confirm the generated code matches the spec.

## Principles

- **Specs drive code**: Specs are inputs to AI code generation, not afterthoughts. Code should be derivable from specs.
- **Single source of truth**: Each topic has one canonical spec file. Avoid duplicating information across specs.
- **Keep current**: Update specs when the product changes. A spec that contradicts the code is a bug — fix the spec first, then regenerate the code.
