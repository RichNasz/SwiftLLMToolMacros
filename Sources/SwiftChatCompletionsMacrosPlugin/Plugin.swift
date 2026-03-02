import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct SwiftChatCompletionsMacrosPlugin: CompilerPlugin {
	let providingMacros: [any Macro.Type] = [
		GenerableMacro.self,
		ToolMacro.self,
		GuideMacro.self,
	]
}
