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
		guard let structDecl = declaration.as(StructDeclSyntax.self) else {
			context.diagnose(.init(
				node: node,
				message: DiagnosticMessage(
					message: "@LLMToolArguments can only be applied to structs",
					diagnosticID: .init(domain: "SwiftLLMToolMacros", id: "notAStruct"),
					severity: .error
				)
			))
			return []
		}
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
			extension \(type.trimmed): LLMToolArguments, Codable, Sendable {}
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
			if binding.accessorBlock != nil {
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
			  identType.name.text == "LLMToolGuide",
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

private func extractRangeBounds(from expr: ExprSyntax) -> (String, String)? {
	if let seq = expr.as(SequenceExprSyntax.self) {
		let elements = Array(seq.elements)
		if elements.count == 3 {
			return (elements[0].trimmedDescription, elements[2].trimmedDescription)
		}
	}
	if let infix = expr.as(InfixOperatorExprSyntax.self) {
		return (infix.leftOperand.trimmedDescription, infix.rightOperand.trimmedDescription)
	}
	return nil
}

private func parseConstraint(from expr: ExprSyntax) -> ConstraintInfo? {
	guard let funcCall = expr.as(FunctionCallExprSyntax.self) else {
		return nil
	}

	let callee = funcCall.calledExpression.trimmedDescription

	if callee.hasSuffix("anyOf") {
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
	} else if callee.hasSuffix("range") {
		if let firstArg = funcCall.arguments.first,
		   let (min, max) = extractRangeBounds(from: firstArg.expression)
		{
			return .range(min, max)
		}
	} else if callee.hasSuffix("doubleRange") {
		if let firstArg = funcCall.arguments.first,
		   let (min, max) = extractRangeBounds(from: firstArg.expression)
		{
			return .doubleRange(min, max)
		}
	} else if callee.hasSuffix("count") {
		if let firstArg = funcCall.arguments.first {
			return .count(firstArg.expression.trimmedDescription)
		}
	} else if callee.hasSuffix("minimumCount") {
		if let firstArg = funcCall.arguments.first {
			return .minimumCount(firstArg.expression.trimmedDescription)
		}
	} else if callee.hasSuffix("maximumCount") {
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
		// Nested LLMToolArguments type — delegate to its jsonSchema
		return "\(typeName).jsonSchema"
	}
}

// MARK: - Diagnostic

struct DiagnosticMessage: SwiftDiagnostics.DiagnosticMessage {
	let message: String
	let diagnosticID: MessageID
	let severity: DiagnosticSeverity
}
