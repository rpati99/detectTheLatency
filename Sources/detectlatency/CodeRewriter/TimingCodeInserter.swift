//
//  TimingCodeInserter.swift
//
//
//  Created by Rachit Prajapati on 7/9/24.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftParser

public final class TimingCodeInserter: SyntaxRewriter {
    
    // Inherited method to iterate the closure code
    public override func visit(_ node: ClosureExprSyntax) -> ExprSyntax {
        // Profiling code
        let timingCode = """
        
                let startTime = DispatchTime.now()
                defer {
                    let endTime = DispatchTime.now()
                    let timeInNanoSec = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
                    let timeInSec = Double(timeInNanoSec) / 1_000_000_000
                    debugPrint(timeInSec)
                }
        """
        
        // Parsing code above to build syntax tree
        let timingCodeStatement = Parser.parse(source: timingCode).statements
        var newStatements : CodeBlockItemListSyntax = timingCodeStatement
        
        // Appending the existing code under closure
        for statement in node.statements {
            newStatements.append(statement)
        }

        // Replacing old code with new code that contains profiling code
        let newBody = node.with(\.statements, newStatements)
        
        // Abstracting to type for merging into parent syntax tree
        return ExprSyntax.init(newBody)
    }
}
