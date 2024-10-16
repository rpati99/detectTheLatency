//
//  CodeExtractorService.swift
//  
//
//  Created by Rachit Prajapati on 6/28/24.
//

import SwiftSyntax

/* Key notes
 1. Service that iterates over the source tree, checks if the name matches to the list of SwiftUI UI element listed below
 2. Trailing closure is a swift style approach of writing additional code when declaring the method
 */

 
public final class CodeExtractorService: SyntaxVisitor {
    // Contains keywords that will only process closures (i.e.:- the code inside SwiftUI UI elements) required
    private let interactiveViewsList: Set<String> = ["Button", "contextMenu", "Slider", "NavigationLink" ]
    private let interactiveViewModifiersList: Set<String> = ["onTapGesture", "onChange", "onDrag", "onDelete", "destructive"]
    
    
    private var isInsideInteractiveElement = false
    public var closureNodes: [ClosureExprSyntax] = [] // Storing the code that is extracted from SwiftUI UI elements
    
    // Superclass method for iterating the syntax tree of inputted Swift code in depth-first manner.
    public override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        processFunctionCall(node)  // Method handles code that is present in SwiftUI UI componenets
        return .visitChildren
    }
    
   
    private func processFunctionCall(_ node: FunctionCallExprSyntax) {
        // Case 1. Handle SwiftUI Views
        if let calledExpression = node.calledExpression.as(DeclReferenceExprSyntax.self) { // Step 1. Abstracting type
            let contains = interactiveViewsList.contains(calledExpression.baseName.text) // Step 2. Check if the base name property matches the interactiveViewsList  that holds SwiftUI UI elements
            
            // Step 3. If contains then perform operation
            if contains {
                isInsideInteractiveElement = true
                processFunctionCallSemantics(node, forComponent: calledExpression.baseName.text)
            }
        }
        
        // Case 2. Handle View Modifiers
        if let memberAccess = node.calledExpression.as(MemberAccessExprSyntax.self) { // Step 1. Abstracting type, where MemberAccessExprsyntax -> trailing closure syntax (code that is to be ran upon user action)
            let contains = interactiveViewModifiersList.contains(memberAccess.declName.baseName.text) // Step 2. Check if the base name property matches the interactiveViewModifiersList that holds SwiftUI UI elements
            
            // Step 3. If contains then perform operation
            if contains {
                let modifierName = memberAccess.declName.baseName.text
                 print("Detected view modifier: \(modifierName)")
                
                // Step 4 Check if there's a trailing closure directly associated with the view modifier
                if let trailingClosure = node.trailingClosure {
                    closureNodes.append(trailingClosure) // Step 4.1 Append the captured code into the list
//                    print("Closure for \(modifierName): \(trailingClosure.statements.description)")
//    
                }
                
                // Step 5 Check if the closure is part of the argument list
                for argument in node.arguments {
                    if let closure = argument.expression.as(ClosureExprSyntax.self) {
                        closureNodes.append(closure) // Step 5.1 Append the captured code into the list
                    }
                }
            }
        }
    }
    
    
    private func processFunctionCallSemantics(_ node: FunctionCallExprSyntax, forComponent component: String) {
        var closureFound = false // Step1. Flag to monitor closure detection
        
        if let trailingClosure = node.trailingClosure { // Step 2. Fetch the code present in SwiftUI View component
            
            // Step 3. Handle different variations of "Button" declaration
            
            /*
             Note:- Button syntax consists of multiple variations
                 1. Without arguments
                 2. With Arguments
             */
            
            
            // Handle 1.
            if component == "Button" {
                
               
                let handleRoleParameter = node.arguments.contains(where: { $0.label?.text == "role" })
                let handleTitleParameter = node.arguments.contains(where: { $0.label?.text == "title" })
                let hasUnlabeledArguments = node.arguments.allSatisfy({ $0.label == nil })
                
                if hasUnlabeledArguments || handleTitleParameter || handleRoleParameter {
                    closureNodes.append(trailingClosure) // Step 4. Append theAppend the captured code into the list
//                    print("Button with trailing closure found ): \(trailingClosure.description)")
                }
                closureFound = true
            }
        }
        
        // Step 5. Handle other SwiftUI View components
        for (_, argument) in node.arguments.enumerated() {
            
            // DEPRECATED:- HANDLING TAPPING OF NAVIGATION LINK
//            if component == "NavigationLink" && index == 0 {
//                if let closure = argument.toClosure {
//                    closureNodes.append(closure)
////                    print("inserted timing code,Navigation link closure code detected, \(insertTimingCode(into: closure).description)")
////                    print("Navigation link closure code detected \(closure.description)")
//                }
//                
//                closureFound = true
//            } else
            
            
            // Handle 2.
            if component == "Button" {
                if let _ = argument.label?.text.contains("action") {
                    if let closure = argument.toClosure {
                        closureNodes.append(closure)
//                        print("Button with action code found \(closure.description)")
                    }
                    
                    closureFound = true
                } else if (node.trailingClosure?.statements.count) ?? 0 > 0 {
                    if let closure = argument.toClosure {
                        closureNodes.append(closure)
//                        print("Button with closure found \(closure.description)")
                    }
                    closureFound = true
                }
            }
            
            // Since iteration is in a recursive depth first pattern, thus exiting the iteration upon detection
            if closureFound {
                break
            }
        }
    }
}

