//
//  ReplaceFunctionRewriter.swift
//  detectlatency
//
//  Created by Rachit Prajapati on 2/28/25.
//

import SwiftSyntax
import Foundation

// Replaces old function with new profiled syntax included code and handles duplication of insertions when a method is detected multiple times.
class ReplaceFunctionRewriter: SyntaxRewriter {
    let targetFunction: String
    let newFunction: FunctionDeclSyntax
    
    init(targetFunction: String, newFunction: FunctionDeclSyntax) {
        self.targetFunction = targetFunction
        self.newFunction = newFunction
        super.init()
    }
    
    override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
        let isStatic = node.modifiers.contains { $0.name.text == "static" } // handle static methods. 
        if node.name.text == targetFunction || isStatic {
            return DeclSyntax(newFunction)
        }
        return super.visit(node)
    }
}
