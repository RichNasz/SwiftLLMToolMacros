// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
	name: "SwiftLLMToolMacros",
	platforms: [
		.macOS(.v13),
		.iOS(.v16)
	],
	products: [
		.library(
			name: "SwiftLLMToolMacros",
			targets: ["SwiftLLMToolMacros"]
		),
	],
	dependencies: [
		.package(url: "https://github.com/swiftlang/swift-syntax.git", from: "602.0.0"),
	],
	targets: [
		// Macro implementation that performs the source transformation of a macro.
		.macro(
			name: "SwiftLLMToolMacrosPlugin",
			dependencies: [
				.product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
				.product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
			]
		),

		// Library that exposes macros as part of its API, which is used in client programs.
		.target(
			name: "SwiftLLMToolMacros",
			dependencies: ["SwiftLLMToolMacrosPlugin"]
		),

		// A test target used to develop the macro implementation.
		.testTarget(
			name: "SwiftLLMToolMacrosTests",
			dependencies: [
				"SwiftLLMToolMacros",
				"SwiftLLMToolMacrosPlugin",
				.product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
			]
		),
	],
	swiftLanguageModes: [.v6]
)
