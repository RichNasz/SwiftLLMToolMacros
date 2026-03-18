import SwiftSyntax
import SwiftSyntaxMacros

/// `@LLMToolGuide` is a marker macro. It generates no code itself.
/// `@LLMToolArguments` reads `@LLMToolGuide` attributes
/// from sibling properties during its expansion to enrich the generated JSON Schema.
public struct GuideMacro: PeerMacro {
	public static func expansion(
		of node: AttributeSyntax,
		providingPeersOf declaration: some DeclSyntaxProtocol,
		in context: some MacroExpansionContext
	) throws -> [DeclSyntax] {
		// Marker macro — no code generation
		return []
	}
}
