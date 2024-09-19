//
//  File.swift
//  detectlatency
//
//  Created by Rachit Prajapati on 9/19/24.
//

import Foundation
import SwiftSyntax

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
