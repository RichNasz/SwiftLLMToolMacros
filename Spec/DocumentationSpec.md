# Documentation Specification

## README.md

### Section Ordering

The README must contain these sections in this exact order:

1. **Title + Badges** (H1)
2. **Table of Contents** — Links to all H2 sections
3. **Overview** (H2)
4. **Quick Start** (H2) — Installation + Basic Usage subsections
5. **How It Works** (H2)
6. **Supported Types** (H2)
7. **@LLMToolGuide Constraints** (H2)
8. **Apple FoundationModels Compatibility** (H2) — Comparison table, links to Apple docs
9. **Designed for SwiftChatCompletionsDSL** (H2)
10. **Requirements** (H2)
11. **Contributing** (H2)
12. **Agent Skill** (H2)
13. **Attribution** (H2)
14. **License** (H2)

### Badge Row

Five badges on the first line after the H1 title, in this order:

```markdown
[![Swift 6.2](https://img.shields.io/badge/Swift-6.2-orange.svg)](https://swift.org)
[![Xcode CLI](https://img.shields.io/badge/Xcode%20CLI-16+-blue.svg)](https://developer.apple.com/xcode/)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-macOS%2013%20%7C%20iOS%2016-lightgrey.svg)](Package.swift)
[![Built with Claude Code](https://img.shields.io/badge/Built%20with-Claude%20Code-blueviolet?logo=claude)](https://claude.ai/code)
```

Update version numbers when requirements change.

### Quick Start Requirements

The Quick Start code example must:

- Be a single, self-contained code block that compiles
- Demonstrate `@LLMToolArguments` with `@LLMToolGuide` descriptions
- Demonstrate `@LLMTool` with doc comment and `Arguments` typealias
- Show `toolDefinition` encoding to JSON
- Include at least one optional property (to show `required` field behavior)

### Tone

- Direct and practical — prioritize showing code over explaining concepts
- Use "you" for the reader
- No marketing language or superlatives

## CLAUDE.md

### Section Ordering

1. **Project Overview** (H2)
2. **Commands** (H2)
3. **Architecture** (H2) — Three-Target Structure, Key Design Decisions, Type-to-Schema Mapping
4. **Dependencies** (H2)
5. **Requirements** (H2)
6. **File Structure** (H2)
7. **Testing Strategy** (H2)

### Quality Standard

CLAUDE.md is the AI's entry point to the codebase. It should contain enough context for AI to navigate the project, understand the architecture, and generate correct code. It should reference spec files as authoritative sources for detailed design decisions. Implementation context belongs in HOW specs; CLAUDE.md should direct AI to consult `Spec/SwiftLLMToolMacros.md` for technical design details.

## Examples/BasicUsage.swift

### Required Demonstrations

The example file must show:

- `@LLMToolArguments` struct with `@LLMToolGuide` descriptions on properties
- `@LLMTool` struct with doc comment, `Arguments` typealias, and `call` method
- Using `toolDefinition` to encode JSON
- Multiple tools (at least 2)
- Nested `@LLMToolArguments` types

### File Header

```swift
// BasicUsage.swift
// Examples of SwiftLLMToolMacros usage
//
// This file demonstrates the core macros and types.
// All examples should compile when imported into a project
// that depends on SwiftLLMToolMacros.
```

## CONTRIBUTING.md

### Content

Must include:

- Getting started steps (fork, clone, branch, test, PR)
- Development setup (requirements, build, test commands)
- Conventional commits format with type table (sourced from ContributingSpec.md)
- AI attribution convention
- PR standards and review checklist
- Link to CODE_OF_CONDUCT.md
- License notice

## CODE_OF_CONDUCT.md

Adopt the Contributor Covenant v2.1. Reference the full text by URL and summarize key principles. Include enforcement contact information.

## SECURITY.md

### Required Sections

1. **Scope** — What is covered (macro-generated code patterns, dependency vulnerabilities)
2. **Reporting** — How to report (GitHub Issue with `security` label)
3. **Response** — Acknowledgment within 48 hours
4. **Disclosure** — No public exploit details in issues

## GitHub Templates

### `.github/ISSUE_TEMPLATE/bug-report.md`

Required fields:

- Description of the bug
- Steps to reproduce
- Expected behavior
- Actual behavior
- Swift version and platform
- Minimal code example

### `.github/ISSUE_TEMPLATE/feature-request.md`

Required fields:

- Description of the feature
- Use case / motivation
- Proposed API (if applicable)
- Alternatives considered

### `.github/pull_request_template.md`

Required sections:

- Summary (1-3 bullet points)
- Test plan (checklist)
- Review checklist (tests pass, docs updated, conventional commits)

## Agent Skill

### `skills/using-swift-llm-tool-macros/SKILL.md`

An [Agent Skill](https://agentskills.io) that gives AI coding assistants package-specific context for using SwiftLLMToolMacros.

### Required Content

The SKILL.md must include:

- YAML frontmatter with `name` (kebab-case, gerund form) and `description` (third-person, under 1024 chars, includes trigger keywords)
- Installation snippet (SPM dependency)
- All three macros: what each does, what it generates, requirements
- Type-to-Schema mapping table
- GuideConstraint reference table (constraint, applies to, example)
- Usage patterns with code examples (inline Arguments, external typealias, nested types)
- Protocol signatures (`LLMToolArguments`, `LLMTool`)
- Using `toolDefinition` (encoding to JSON)
- Common pitfalls (struct-only, Arguments resolution, call signature, constraint type matching, FoundationModels coexistence, optional handling, doc comment format)

### Constraints

- Body must be under 500 lines
- No reference files — the API surface fits within the SKILL.md itself
- Only covers package-specific knowledge; assumes the agent already knows Swift

### README Agent Skill Section

The README's "Agent Skill" section must:

- State that the skill is optional and not required to use the package
- Note that only agents implementing the [agentskills.io](https://agentskills.io) spec can use skills
- Explain that adding an SPM dependency does not make the skill discoverable — SPM downloads sources into `.build/checkouts/`, which agents don't scan
- Provide installation instructions: copy the skill folder into the project's `skills/` directory (or wherever the agent is configured to look)
- Include a "Spec-Driven Development" subsection linking to `docs/SpecDrivenDevelopment.md` and `Examples/Specs/`

## docs/SpecDrivenDevelopment.md

### Required Sections

1. **What Is Spec-Driven Development?** — Definition and opt-in framing
2. **The Three Tools** — Subsections for WHAT Specs, HOW Specs, and Agent Skills
3. **How They Work Together** — Narrative showing the workflow from spec to generated code
4. **Graceful Degradation** — What works without the Skill, what works without specs
5. **Getting Started** — Numbered steps (install skill, write WHAT, write HOW, ask agent)
6. **Example** — Links to sample specs in `Examples/Specs/`

### Constraints

- Must frame SDD as optional, not prescriptive
- Must not duplicate SKILL.md content; link to it instead
- Must link to sample specs in `Examples/Specs/`
- Tone: direct, practical, no methodology evangelism

## Examples/Specs/

### Purpose

Sample WHAT and HOW specs demonstrating how a package consumer would use spec-driven development to build a tool using SwiftLLMToolMacros.

### Required Files

- `RecipeSearchTool-WHAT.md` — WHAT spec for a recipe search tool
- `RecipeSearchTool-HOW.md` — HOW spec for the same tool

### WHAT Spec Requirements

- Must define tool name, description, and arguments table
- Must include at least one property of each type category: String, Int, Double, Bool, Optional, Array, Nested type
- Must include at least one constraint from each constraint category (anyOf, range, minimumCount)
- Must include acceptance criteria as a checklist

### HOW Spec Requirements

- Must reference SwiftLLMToolMacros by import name
- Must name specific macros (`@LLMToolArguments`, `@LLMTool`, `@LLMToolGuide`)
- Must show expected JSON Schema output shape
- Must cover component ordering (nested type defined before referencing type)
