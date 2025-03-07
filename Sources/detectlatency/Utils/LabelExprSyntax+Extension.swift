//
//  LabelExprSyntax+Extension.swift
//  
//
//  Created by Rachit Prajapati on 6/28/24.
//


import SwiftSyntax

// Convenience that converts directly to ClosureExprSyntax type from retrieved LabeledExprSyntaxType
public extension LabeledExprSyntax {
    var toClosure: ClosureExprSyntax? {
        return self.expression.as(ClosureExprSyntax.self)
    }
}


