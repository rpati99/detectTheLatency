//
//  ClosureReplacer.swift
//  detectlatency
//
//  Created by Rachit Prajapati on 9/19/24.
//

import Foundation
import SwiftSyntax

/*
 Think about how to handle additions and before that think on checking the flow regarding insertion of timers.
 
 TODO:- Handle inserter inside flow control
 Cover all usecases of button and views
 Cover all usecases of view modifiers
 */

public class ClosureReplacer : SyntaxRewriter {
    public let closureReplacement: [ClosureExprSyntax: ClosureExprSyntax]
    
    init(closureReplacement: [ClosureExprSyntax: ClosureExprSyntax]) {
        self.closureReplacement = closureReplacement
    }
    
    public override func visit(_ node: ClosureExprSyntax) -> ExprSyntax {
        if let newClosure = closureReplacement[node] {
            return newClosure.as(ExprSyntax.self)!
        }
        return super.visit(node)
    }
}
