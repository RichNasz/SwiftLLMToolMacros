# Documentation Specification

## README.md

### Section Ordering

The README must contain these sections in this exact order:

1. **Title + Badges** (H1)
2. **Overview** (H2)
3. **Quick Start** (H2) — Installation + Basic Usage subsections
4. **Supported Types** (H2)
5. **@Guide Constraints** (H2)
6. **Requirements** (H2)
7. **Contributing** (H2)
8. **License** (H2)

### Badge Row

Three badges on the first line after the H1 title, in this order:

```markdown
[![Swift 6.2](https://img.shields.io/badge/Swift-6.2-orange.svg)](https://swift.org)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-macOS%2013%20%7C%20iOS%2016-lightgrey.svg)](Package.swift)
```

Update version numbers when requirements change.

### Quick Start Requirements

The Quick Start code example must:

- Be a single, self-contained code block that compiles
- Demonstrate `@Generable` with `@Guide` descriptions
- Demonstrate `@Tool` with doc comment and `Arguments` typealias
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

CLAUDE.md is the AI's entry point to the codebase. It should contain enough context for AI to navigate the project, understand the architecture, and generate correct code. It should reference spec files as authoritative sources for detailed design decisions. Implementation context belongs in HOW specs; CLAUDE.md should direct AI to consult `Spec/SwiftChatCompletionsMacros.md` for technical design details.

## Examples/BasicUsage.swift

### Required Demonstrations

The example file must show:

- `@Generable` struct with `@Guide` descriptions on properties
- `@Tool` struct with doc comment, `Arguments` typealias, and `call` method
- Using `toolDefinition` to encode JSON
- Multiple tools (at least 2)
- Nested `@Generable` types

### File Header

```swift
// BasicUsage.swift
// Examples of SwiftChatCompletionsMacros usage
//
// This file demonstrates the core macros and types.
// All examples should compile when imported into a project
// that depends on SwiftChatCompletionsMacros.
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
