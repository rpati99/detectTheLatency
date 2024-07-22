//
//  File.swift
//  
//
//  Created by Rachit Prajapati on 6/28/24.
//

import Foundation
import SwiftSyntax

// To convert directly to ClosureExprSyntax type from retrieved LabeledExprSyntaxType
extension LabeledExprSyntax {
    var toClosure: ClosureExprSyntax? {
        return self.expression.as(ClosureExprSyntax.self)
    }
}


