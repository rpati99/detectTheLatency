//
//  UIElementDetector.swift
//  callgraphbuilder
//
//  Created by Rachit Prajapati on 1/20/25.
//

import Foundation
import SwiftSyntax
import SwiftParser
import SwiftSyntaxBuilder

// Detects the the UI Elements
class UIElementDetector: SyntaxVisitor {
    private let interactiveViewsList: Set<String>
    private let interactiveViewModifiersList: Set<String>
    private var objectTypes: [String: String] = [:]
    private(set) var collectedFunctions: [String] = []

    init(interactiveViewsList: Set<String>, interactiveViewModifiersList: Set<String>) {
        self.interactiveViewsList = interactiveViewsList
        self.interactiveViewModifiersList = interactiveViewModifiersList
        super.init(viewMode: .sourceAccurate)
    }

    public override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {

        // Process UI elements
        if let identifier = node.calledExpression.as(DeclReferenceExprSyntax.self),
           interactiveViewsList.contains(identifier.baseName.text) {
//            print("[Debug] Processing UI element: \(identifier.baseName.text)")
            processUIElement(node, componentName: identifier.baseName.text)
        }

        // Process modifiers
        if let memberAccess = node.calledExpression.as(MemberAccessExprSyntax.self),
           interactiveViewModifiersList.contains(memberAccess.declName.baseName.text) {
//            print("[Debug] Processing modifier: \(memberAccess.declName.baseName.text)")
            processViewModifier(node, modifierName: memberAccess.declName.baseName.text)
        }

        return .visitChildren
    }

    private func processUIElement(_ node: FunctionCallExprSyntax, componentName: String) {
//        print("[processUIElement] Processing \(componentName)")

        // Process trailing closures in the UI element
        if let trailingClosure = node.trailingClosure {
            processClosure(trailingClosure)
        }

        // Process argument closures in the UI element
        for argument in node.arguments {
            if let closure = argument.expression.as(ClosureExprSyntax.self) {
                processClosure(closure)
            }
        }
    }

    private func processViewModifier(_ node: FunctionCallExprSyntax, modifierName: String) {
//        print("[processViewModifier] Processing \(modifierName)")

        // Process trailing closures in the modifier
        if let trailingClosure = node.trailingClosure {
            processClosure(trailingClosure)
        }

        // Process argument closures in the modifier
        for argument in node.arguments {
            if let closure = argument.expression.as(ClosureExprSyntax.self) {
                processClosure(closure)
            }
        }
    }

    private func processClosure(_ closure: ClosureExprSyntax) {
        let functionVisitor = FunctionBodyVisitor(objectTypes: objectTypes)
        functionVisitor.walk(closure)
        collectedFunctions.append(contentsOf: functionVisitor.calledFunctions)
        objectTypes.merge(functionVisitor.objectTypes, uniquingKeysWith: { $1 })
    }
}
