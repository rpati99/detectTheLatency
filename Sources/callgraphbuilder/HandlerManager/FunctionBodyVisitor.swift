//
//  FunctionBodyVisitor.swift
//  callgraphbuilder
//
//  Created by Rachit Prajapati on 1/17/25.
//

import Foundation
import SwiftSyntax

// Service that extracts functions which are declared inside the functions and also perform differentiation from object type declaration
// eg. class Authservice {} -> AuthService() [Here AuthService is not a function], func performAuth(_) {} -> performAuth() [Here performAuth is a function despite identical initialization]
public class FunctionBodyVisitor: SyntaxVisitor {
    var calledFunctions: [String] = []
    var objectTypes: [String: String]
    
    init(objectTypes: [String: String]) {
        self.objectTypes = objectTypes
        super.init(viewMode: .sourceAccurate)
    }
    
    
    public override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        if let calledFunction = node.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text {
//            print("[FunctionBodyVisitor] Found function call: \(calledFunction)")
            if !objectTypes.values.contains(calledFunction) {
                calledFunctions.append(calledFunction)
            }
            //            calledFunctions.append(calledFunction)
        } else if let memberAccess = node.calledExpression.as(MemberAccessExprSyntax.self) {
            if let base = memberAccess.base?.as(FunctionCallExprSyntax.self) {
                // Handle inline object instantiation (e.g., `AuthService().func2()`)
                if let objectType = base.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text {
                    let methodName = memberAccess.declName.baseName.text
//                    print("[FunctionBodyVisitor] Found inline object method call: \(objectType).\(methodName)")
                    calledFunctions.append("\(objectType).\(methodName)")
                }
            } else if let base = memberAccess.base?.as(DeclReferenceExprSyntax.self)?.baseName.text {
                let methodName = memberAccess.declName.baseName.text
                if let objectType = objectTypes[base] {
//                    print("[FunctionBodyVisitor] Found object method call: \(objectType).\(methodName)")
                    calledFunctions.append("\(objectType).\(methodName)")
                } else {
//                    print("[FunctionBodyVisitor] Found unresolved object method call: \(base).\(methodName)")
                    calledFunctions.append("\(base).\(methodName)")
                }
            }
        }
        return .visitChildren
    }
    
    /// Handles async function assignments (`async let task = function()`)
    public override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        for binding in node.bindings {
            if (node.bindingSpecifier.text == "let" || node.bindingSpecifier.text == "var"),
               node.modifiers.contains(where: { $0.name.text == "async" }),
               let functionCall = binding.initializer?.value.as(FunctionCallExprSyntax.self),
               let functionName = functionCall.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text {
                
                print("[FunctionBodyVisitor] Detected async \(node.bindingSpecifier.text) function call: \(functionName)")
                calledFunctions.append(functionName)
            }
        }
        return .visitChildren
    }
    
    
    /// Detects `if-else` statements
        public override func visit(_ node: IfExprSyntax) -> SyntaxVisitorContinueKind {
//            print("[FunctionBodyVisitor] Encountered 'if' statement.")
            if node.elseBody != nil {
//                print("[FunctionBodyVisitor] Encountered 'else' block.")
            }
            return .visitChildren
        }

        /// Detects `if let` or `guard let` statements
        public override func visit(_ node: ConditionElementSyntax) -> SyntaxVisitorContinueKind {
            if let patternBinding = node.condition.as(OptionalBindingConditionSyntax.self), patternBinding.bindingSpecifier.text == "let" {
                if node.parent?.as(IfExprSyntax.self) != nil {
//                    print("[FunctionBodyVisitor] Encountered 'if let' statement.")
                } else if node.parent?.as(GuardStmtSyntax.self) != nil {
//                    print("[FunctionBodyVisitor] Encountered 'guard let' statement.")
                }
            }
            return .visitChildren
        }

        /// Detects `guard let` statements explicitly
        public override func visit(_ node: GuardStmtSyntax) -> SyntaxVisitorContinueKind {
//            print("[FunctionBodyVisitor] Encountered 'guard' statement.")
            return .visitChildren
        }
}
