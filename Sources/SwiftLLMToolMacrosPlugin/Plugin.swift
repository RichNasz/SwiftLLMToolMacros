import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct SwiftLLMToolMacrosPlugin: CompilerPlugin {
	let providingMacros: [any Macro.Type] = [
		GenerableMacro.self,
		ToolMacro.self,
		GuideMacro.self,
	]
}
