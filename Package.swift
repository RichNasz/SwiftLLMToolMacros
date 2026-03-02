// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
	name: "SwiftChatCompletionsMacros",
	platforms: [
		.macOS(.v13),
		.iOS(.v16)
	],
	products: [
		.library(
			name: "SwiftChatCompletionsMacros",
			targets: ["SwiftChatCompletionsMacros"]
		),
	],
	dependencies: [
		.package(url: "https://github.com/swiftlang/swift-syntax.git", from: "602.0.0"),
	],
	targets: [
		// Macro implementation that performs the source transformation of a macro.
		.macro(
			name: "SwiftChatCompletionsMacrosPlugin",
			dependencies: [
				.product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
				.product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
			]
		),

		// Library that exposes macros as part of its API, which is used in client programs.
		.target(
			name: "SwiftChatCompletionsMacros",
			dependencies: ["SwiftChatCompletionsMacrosPlugin"]
		),

		// A test target used to develop the macro implementation.
		.testTarget(
			name: "SwiftChatCompletionsMacrosTests",
			dependencies: [
				"SwiftChatCompletionsMacros",
				"SwiftChatCompletionsMacrosPlugin",
				.product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
			]
		),
	]
)
