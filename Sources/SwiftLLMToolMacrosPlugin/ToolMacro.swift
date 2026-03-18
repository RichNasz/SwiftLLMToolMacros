import Foundation
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

public struct ToolMacro {}

// MARK: - MemberMacro

extension ToolMacro: MemberMacro {
	public static func expansion(
		of node: AttributeSyntax,
		providingMembersOf declaration: some DeclGroupSyntax,
		conformingTo protocols: [TypeSyntax],
		in context: some MacroExpansionContext
	) throws -> [DeclSyntax] {
		guard let structDecl = declaration.as(StructDeclSyntax.self) else {
			context.diagnose(.init(
				node: node,
				message: DiagnosticMessage(
					message: "@LLMTool can only be applied to structs",
					diagnosticID: MessageID(domain: "SwiftLLMToolMacros", id: "toolNotAStruct"),
					severity: .error
				)
			))
			return []
		}

		let structName = structDecl.name.text
		let toolName = pascalCaseToSnakeCase(structName)

		// Extract description from doc comment
		let description = extractDocComment(from: structDecl.leadingTrivia)
			?? "No description provided."

		// Find the Arguments type to reference
		let hasArguments = findNestedType(named: "Arguments", in: structDecl) != nil
		let hasCallMethod = findCallMethod(in: structDecl) != nil

		var members: [DeclSyntax] = []

		let nameDecl: DeclSyntax = """
			public static let name: String = "\(raw: toolName)"
			"""
		members.append(nameDecl)

		let descDecl: DeclSyntax = """
			public static let description: String = "\(raw: escapeStringLiteral(description))"
			"""
		members.append(descDecl)

		if hasArguments {
			let defDecl: DeclSyntax = """
				public static var toolDefinition: ToolDefinition {
					ToolDefinition(
						name: name,
						description: description,
						parameters: Arguments.jsonSchema
					)
				}
				"""
			members.append(defDecl)
		} else if hasCallMethod {
			// If there's a call method but no nested Arguments type,
			// look at the call method's parameter type
			if let callMethod = findCallMethod(in: structDecl),
			   let paramType = extractArgumentsType(from: callMethod)
			{
				let defDecl: DeclSyntax = """
					public static var toolDefinition: ToolDefinition {
						ToolDefinition(
							name: name,
							description: description,
							parameters: \(raw: paramType).jsonSchema
						)
					}
					"""
				members.append(defDecl)
			}
		}

		return members
	}
}

// MARK: - ExtensionMacro

extension ToolMacro: ExtensionMacro {
	public static func expansion(
		of node: AttributeSyntax,
		attachedTo declaration: some DeclGroupSyntax,
		providingExtensionsOf type: some TypeSyntaxProtocol,
		conformingTo protocols: [TypeSyntax],
		in context: some MacroExpansionContext
	) throws -> [ExtensionDeclSyntax] {
		guard declaration.as(StructDeclSyntax.self) != nil else {
			return []
		}

		let ext: DeclSyntax = """
			extension \(type.trimmed): LLMTool {}
			"""
		return [ext.cast(ExtensionDeclSyntax.self)]
	}
}

// MARK: - PeerMacro

extension ToolMacro: PeerMacro {
	public static func expansion(
		of node: AttributeSyntax,
		providingPeersOf declaration: some DeclSyntaxProtocol,
		in context: some MacroExpansionContext
	) throws -> [DeclSyntax] {
		// Peer expansion is only for free functions — not structs
		// For struct mode, MemberMacro and ExtensionMacro handle everything
		return []
	}
}

// MARK: - Helpers

private func pascalCaseToSnakeCase(_ name: String) -> String {
	var result = ""
	for (index, char) in name.enumerated() {
		if char.isUppercase {
			if index > 0 {
				result += "_"
			}
			result += char.lowercased()
		} else {
			result += String(char)
		}
	}
	return result
}

private func extractDocComment(from trivia: Trivia) -> String? {
	var lines: [String] = []
	for piece in trivia {
		switch piece {
		case .docLineComment(let text):
			// Remove "/// " prefix
			let content = text.hasPrefix("/// ")
				? String(text.dropFirst(4))
				: (text.hasPrefix("///") ? String(text.dropFirst(3)) : text)
			lines.append(content)
		case .docBlockComment(let text):
			// Remove "/** " prefix and " */" suffix
			var content = text
			if content.hasPrefix("/**") { content = String(content.dropFirst(3)) }
			if content.hasSuffix("*/") { content = String(content.dropLast(2)) }
			lines.append(content.trimmingCharacters(in: .whitespacesAndNewlines))
		default:
			break
		}
	}

	if lines.isEmpty { return nil }

	// Return first paragraph (up to first empty line or "- Parameter")
	var result: [String] = []
	for line in lines {
		let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
		if trimmed.isEmpty || trimmed.hasPrefix("- Parameter") || trimmed.hasPrefix("- Returns") {
			break
		}
		result.append(trimmed)
	}

	return result.isEmpty ? nil : result.joined(separator: " ")
}

private func findNestedType(named name: String, in structDecl: StructDeclSyntax) -> DeclSyntax? {
	for member in structDecl.memberBlock.members {
		if let structMember = member.decl.as(StructDeclSyntax.self),
		   structMember.name.text == name
		{
			return DeclSyntax(structMember)
		}
		if let enumMember = member.decl.as(EnumDeclSyntax.self),
		   enumMember.name.text == name
		{
			return DeclSyntax(enumMember)
		}
		if let typeAlias = member.decl.as(TypeAliasDeclSyntax.self),
		   typeAlias.name.text == name
		{
			return DeclSyntax(typeAlias)
		}
	}
	return nil
}

private func findCallMethod(in structDecl: StructDeclSyntax) -> FunctionDeclSyntax? {
	for member in structDecl.memberBlock.members {
		if let funcDecl = member.decl.as(FunctionDeclSyntax.self),
		   funcDecl.name.text == "call"
		{
			return funcDecl
		}
	}
	return nil
}

private func extractArgumentsType(from funcDecl: FunctionDeclSyntax) -> String? {
	for param in funcDecl.signature.parameterClause.parameters {
		if param.firstName.text == "arguments" {
			return param.type.trimmedDescription
		}
	}
	return nil
}

private func escapeStringLiteral(_ text: String) -> String {
	var result = ""
	for char in text {
		switch char {
		case "\\": result += "\\\\"
		case "\"": result += "\\\""
		case "\n": result += " "
		default: result += String(char)
		}
	}
	return result
}
