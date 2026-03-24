# Spec-Driven Development with SwiftLLMToolMacros

## What Is Spec-Driven Development?

Spec-driven development (SDD) is a workflow where you write specifications before code. You describe what a tool should do (WHAT spec) and how to implement it (HOW spec), then hand the specs to an AI coding agent to generate the implementation.

SDD is entirely optional. You can use SwiftLLMToolMacros without writing any specs. But if you use an AI coding agent, specs reduce back-and-forth and produce more accurate results on the first pass.

## The Three Tools

### WHAT Specs -- Define the Product

A WHAT spec describes what the tool does from the user's (or LLM's) perspective. It lists the tool name, description, arguments with types and constraints, and acceptance criteria.

A WHAT spec does not prescribe implementation. It answers: *what should exist when this is done?*

Write a WHAT spec when you are defining a new tool or changing what an existing tool accepts.

### HOW Specs -- Guide the Implementation

A HOW spec translates WHAT requirements into technical decisions. It names the specific macros to use, defines struct layout and annotation placement, specifies component ordering, and shows the expected JSON Schema output.

A HOW spec gives the AI agent enough detail to generate code without ambiguity. It answers: *how should this be built using SwiftLLMToolMacros?*

Write a HOW spec after the WHAT spec is settled, before asking an agent to generate code.

### Agent Skills -- Provide Package Knowledge

[Agent Skills](https://agentskills.io) give the AI coding agent domain-specific knowledge about a package. SwiftLLMToolMacros ships two complementary skills:

**`using-swift-llm-tool-macros`** (reference skill) teaches the agent what the package provides:

- The three macros and what each generates
- Type-to-schema mapping rules
- `@LLMToolGuide` constraint options
- Common pitfalls (struct-only restriction, doc comment requirements, argument resolution)

**`design-llm-tool`** (process skill) teaches the agent how to generate correct code:

- A 7-step decision workflow: name, types, required/optional, constraints, structure, nesting, assembly
- Explicit decision rules for each choice (not just options, but when to use each)
- Where macro code ends and DSL integration begins

Without the skills, the agent relies on general training, which may be outdated or incomplete. With both skills loaded, the agent knows the current API surface and the correct design process.

See the [README](../README.md#installing-the-skills) for installation instructions.

## How They Work Together

Each tool covers a different layer. Together they form a complete pipeline from requirements to working code:

1. **You write a WHAT spec** -- "I want a RecipeSearch tool with these arguments, types, and constraints"
2. **You write a HOW spec** -- "Use `@LLMToolArguments` on this struct, annotate these properties with `@LLMToolGuide`, define the nested type first"
3. **The agent reads the HOW spec and has the Skill loaded** -- it knows both *your* requirements and *the package's* API, so it generates correct Swift code
4. **You review and run `swift build && swift test`** -- verify the output matches the WHAT spec's acceptance criteria

The WHAT spec is durable -- it survives package version changes because it describes behavior, not API. The HOW spec is version-specific -- it references current macro names and patterns. The Skill ensures the agent knows the current API even if the HOW spec has a gap.

## Graceful Degradation

### Without the Skill

The agent can still follow a HOW spec, but may make mistakes with constraint syntax, macro parameters, or protocol requirements. A detailed HOW spec compensates partially, but the Skill makes the agent fluent.

### Without Specs

The agent can still use the Skill to write tools from a natural-language description. This works well for simple tools. For complex tools with many arguments, nested types, and constraints, specs prevent miscommunication and serve as a reviewable contract.

### Without Both

You write code manually using the [README](../README.md) and [Examples](../Examples/BasicUsage.swift) as reference. The macros work the same regardless of workflow.

## Getting Started

1. **Install the Agent Skill** (optional) -- copy `skills/using-swift-llm-tool-macros/` into your project's `skills/` directory. See the [README](../README.md#installing-the-skill) for details.

2. **Write a WHAT spec** -- describe the tool, its arguments, types, constraints, and acceptance criteria. See [`Examples/Specs/RecipeSearchTool-WHAT.md`](../Examples/Specs/RecipeSearchTool-WHAT.md) for a template.

3. **Write a HOW spec** -- translate the WHAT into macro-specific implementation guidance. See [`Examples/Specs/RecipeSearchTool-HOW.md`](../Examples/Specs/RecipeSearchTool-HOW.md) for a template.

4. **Ask your agent to implement** -- point the agent at the HOW spec and review the generated code.

## Example

See the complete worked example in [`Examples/Specs/`](../Examples/Specs/):

- [RecipeSearchTool-WHAT.md](../Examples/Specs/RecipeSearchTool-WHAT.md) -- Product requirements for a recipe search tool
- [RecipeSearchTool-HOW.md](../Examples/Specs/RecipeSearchTool-HOW.md) -- Implementation guidance using SwiftLLMToolMacros
