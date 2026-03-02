import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

public struct GenerableMacro {}

// MARK: - MemberMacro

extension GenerableMacro: MemberMacro {
	public static func expansion(
		of node: AttributeSyntax,
		providingMembersOf declaration: some DeclGroupSyntax,
		conformingTo protocols: [TypeSyntax],
		in context: some MacroExpansionContext
	) throws -> [DeclSyntax] {
		guard declaration.as(StructDeclSyntax.self) != nil else {
			context.diagnose(.init(
				node: node,
				message: DiagnosticMessage(
					message: "@Generable can only be applied to structs",
					diagnosticID: .init(domain: "SwiftChatCompletionsMacros", id: "notAStruct"),
					severity: .error
				)
			))
			return []
		}

		let structDecl = declaration.as(StructDeclSyntax.self)!
		let properties = extractStoredProperties(from: structDecl)

		var propertyEntries: [String] = []
		var requiredNames: [String] = []

		for prop in properties {
			let schemaExpr = schemaExpression(for: prop)
			propertyEntries.append("(\"\(prop.name)\", \(schemaExpr))")
			if !prop.isOptional {
				requiredNames.append("\"\(prop.name)\"")
			}
		}

		let propertiesArray = propertyEntries.joined(separator: ", ")
		let requiredArray = requiredNames.joined(separator: ", ")

		let decl: DeclSyntax = """
			public static var jsonSchema: JSONSchemaValue {
				.object(
					properties: [\(raw: propertiesArray)],
					required: [\(raw: requiredArray)]
				)
			}
			"""

		return [decl]
	}
}

// MARK: - ExtensionMacro

extension GenerableMacro: ExtensionMacro {
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
			extension \(type.trimmed): Generable, Codable, Sendable {}
			"""
		return [ext.cast(ExtensionDeclSyntax.self)]
	}
}

// MARK: - Property Extraction

private struct PropertyInfo {
	let name: String
	let typeName: String
	let isOptional: Bool
	let guideDescription: String?
	let guideConstraint: ConstraintInfo?
}

enum ConstraintInfo {
	case anyOf([String])
	case range(String, String) // min, max as string literals
	case doubleRange(String, String)
	case count(String)
	case minimumCount(String)
	case maximumCount(String)
}

private func extractStoredProperties(from structDecl: StructDeclSyntax) -> [PropertyInfo] {
	var properties: [PropertyInfo] = []

	for member in structDecl.memberBlock.members {
		guard let varDecl = member.decl.as(VariableDeclSyntax.self),
			  varDecl.bindingSpecifier.tokenKind == .keyword(.var) || varDecl.bindingSpecifier.tokenKind == .keyword(.let)
		else {
			continue
		}

		// Skip computed properties (those with accessor blocks containing get/set)
		for binding in varDecl.bindings {
			if let accessorBlock = binding.accessorBlock {
				// If it has accessors, it's computed — skip
				_ = accessorBlock
				continue
			}

			guard let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
				  let typeAnnotation = binding.typeAnnotation
			else {
				continue
			}

			let name = pattern.identifier.text
			let (typeName, isOptional) = unwrapOptional(typeAnnotation.type)

			let (guideDesc, constraint) = extractGuide(from: varDecl.attributes)

			properties.append(PropertyInfo(
				name: name,
				typeName: typeName,
				isOptional: isOptional,
				guideDescription: guideDesc,
				guideConstraint: constraint
			))
		}
	}

	return properties
}

private func unwrapOptional(_ type: TypeSyntax) -> (String, Bool) {
	if let optional = type.as(OptionalTypeSyntax.self) {
		return (optional.wrappedType.trimmedDescription, true)
	}
	if let identType = type.as(IdentifierTypeSyntax.self),
	   identType.name.text == "Optional",
	   let genericArgs = identType.genericArgumentClause,
	   let firstArg = genericArgs.arguments.first
	{
		return (firstArg.argument.trimmedDescription, true)
	}
	return (type.trimmedDescription, false)
}

private func extractGuide(from attributes: AttributeListSyntax) -> (String?, ConstraintInfo?) {
	for attribute in attributes {
		guard let attr = attribute.as(AttributeSyntax.self),
			  let identType = attr.attributeName.as(IdentifierTypeSyntax.self),
			  identType.name.text == "Guide",
			  let arguments = attr.arguments?.as(LabeledExprListSyntax.self)
		else {
			continue
		}

		var description: String?
		var constraint: ConstraintInfo?

		for arg in arguments {
			if arg.label?.text == "description",
			   let stringLiteral = arg.expression.as(StringLiteralExprSyntax.self)
			{
				description = stringLiteral.segments.description
			} else if arg.label == nil || arg.label?.text == "_" {
				// This is the constraint argument
				constraint = parseConstraint(from: arg.expression)
			}
		}

		return (description, constraint)
	}

	return (nil, nil)
}

private func parseConstraint(from expr: ExprSyntax) -> ConstraintInfo? {
	guard let funcCall = expr.as(FunctionCallExprSyntax.self) else {
		// Check for .anyOf, .range, etc.
		if let memberAccess = expr.as(MemberAccessExprSyntax.self) {
			_ = memberAccess
		}
		return nil
	}

	let callee = funcCall.calledExpression.trimmedDescription

	if callee.hasSuffix("anyOf") || callee == ".anyOf" {
		if let firstArg = funcCall.arguments.first,
		   let arrayExpr = firstArg.expression.as(ArrayExprSyntax.self)
		{
			let values = arrayExpr.elements.compactMap { element -> String? in
				if let str = element.expression.as(StringLiteralExprSyntax.self) {
					return str.segments.description
				}
				return nil
			}
			return .anyOf(values)
		}
	} else if callee.hasSuffix("range") || callee == ".range" {
		if let firstArg = funcCall.arguments.first,
		   let rangeExpr = firstArg.expression.as(SequenceExprSyntax.self)
		{
			let elements = Array(rangeExpr.elements)
			if elements.count == 3 {
				return .range(
					elements[0].trimmedDescription,
					elements[2].trimmedDescription
				)
			}
		}
	} else if callee.hasSuffix("doubleRange") || callee == ".doubleRange" {
		if let firstArg = funcCall.arguments.first,
		   let rangeExpr = firstArg.expression.as(SequenceExprSyntax.self)
		{
			let elements = Array(rangeExpr.elements)
			if elements.count == 3 {
				return .doubleRange(
					elements[0].trimmedDescription,
					elements[2].trimmedDescription
				)
			}
		}
	} else if callee.hasSuffix("count") || callee == ".count" {
		if let firstArg = funcCall.arguments.first {
			return .count(firstArg.expression.trimmedDescription)
		}
	} else if callee.hasSuffix("minimumCount") || callee == ".minimumCount" {
		if let firstArg = funcCall.arguments.first {
			return .minimumCount(firstArg.expression.trimmedDescription)
		}
	} else if callee.hasSuffix("maximumCount") || callee == ".maximumCount" {
		if let firstArg = funcCall.arguments.first {
			return .maximumCount(firstArg.expression.trimmedDescription)
		}
	}

	return nil
}

// MARK: - Schema Expression Generation

private func schemaExpression(for prop: PropertyInfo) -> String {
	let baseSchema = typeToSchemaExpression(prop.typeName, description: prop.guideDescription, constraint: prop.guideConstraint)
	return baseSchema
}

private func typeToSchemaExpression(_ typeName: String, description: String? = nil, constraint: ConstraintInfo? = nil) -> String {
	let descArg = description.map { "description: \"\($0)\"" }

	switch typeName {
	case "String":
		var args: [String] = []
		if let d = descArg { args.append(d) }
		if case let .anyOf(values) = constraint {
			let enumList = values.map { "\"\($0)\"" }.joined(separator: ", ")
			args.append("enumValues: [\(enumList)]")
		}
		return args.isEmpty ? ".string()" : ".string(\(args.joined(separator: ", ")))"

	case "Int":
		var args: [String] = []
		if let d = descArg { args.append(d) }
		if case let .range(min, max) = constraint {
			args.append("minimum: \(min)")
			args.append("maximum: \(max)")
		}
		return args.isEmpty ? ".integer()" : ".integer(\(args.joined(separator: ", ")))"

	case "Double":
		var args: [String] = []
		if let d = descArg { args.append(d) }
		if case let .doubleRange(min, max) = constraint {
			args.append("minimum: \(min)")
			args.append("maximum: \(max)")
		}
		return args.isEmpty ? ".number()" : ".number(\(args.joined(separator: ", ")))"

	case "Bool":
		return descArg.map { ".boolean(\($0))" } ?? ".boolean()"

	default:
		// Check for array types
		if typeName.hasPrefix("[") && typeName.hasSuffix("]") {
			let elementType = String(typeName.dropFirst().dropLast())
			let itemSchema = typeToSchemaExpression(elementType)
			return ".array(items: \(itemSchema))"
		}
		// Nested Generable type — delegate to its jsonSchema
		return "\(typeName).jsonSchema"
	}
}

// MARK: - Diagnostic

struct DiagnosticMessage: SwiftDiagnostics.DiagnosticMessage {
	let message: String
	let diagnosticID: MessageID
	let severity: DiagnosticSeverity
}
