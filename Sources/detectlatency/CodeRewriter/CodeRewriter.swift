//
//  File.swift
//  
//
//  Created by Rachit Prajapati on 7/9/24.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import Foundation
import SwiftParser


class TimingCodeInserter: SyntaxRewriter {
    override func visit(_ node: ClosureExprSyntax) -> ExprSyntax {
        // The timing code as a string
        let timingCode = """
        
                let startTime = DispatchTime.now()
                defer {
                    let endTime = DispatchTime.now()
                    let timeInNanoSec = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
                    let timeInSec = Double(timeInNanoSec) / 1_000_000_000
                    debugPrint(timeInSec)
                }
        """
        
        let timingCodeStatement = Parser.parse(source: timingCode).statements
        var newStatements : CodeBlockItemListSyntax = timingCodeStatement
        for statement in node.statements {
            newStatements.append(statement)
        }

        let newBody = node.with(\.statements, newStatements)
        
        return newBody.as(ExprSyntax.self)!
    }
}
