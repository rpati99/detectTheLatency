//
//  InteractiveElementFinder.swift
//  callgraphbuilder
//
//  Created by Rachit Prajapati on 1/15/25.
//

import Foundation
import SwiftSyntax

// Service used under main() which filters Swift files that contain UI Elements
public class InteractiveElementFinder: SyntaxVisitor {
    var containsInteractiveElement = false // Flag to indicate if any interactive element is found
    
    // SwiftUI UI Views list
    private let interactiveViewsList: Set<String> = ["Button", "contextMenu", "Slider", "NavigationLink"]
    
    // SwiftUI UI View modifier list
    private let interactiveViewModifiersList: Set<String> = ["onTapGesture", "onChange", "onDrag", "onDelete", "destructive"]
    
    override public func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        // Check if the call is to an interactive view
        if let identifier = node.calledExpression.as(DeclReferenceExprSyntax.self),
           interactiveViewsList.contains(identifier.baseName.text) {
            containsInteractiveElement = true
            return .skipChildren // No need to continue visiting
        }
        
        // Check if the call is to an interactive view modifier
        if let memberAccess = node.calledExpression.as(MemberAccessExprSyntax.self),
           interactiveViewModifiersList.contains(memberAccess.declName.baseName.text) {
            containsInteractiveElement = true
            return .skipChildren // No need to continue visiting
        }
        
        return .visitChildren
    }
}
