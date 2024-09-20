//  SwiftSyntaxModifier.swift
//  detectlatency
//
//  Created by Rachit Prajapati on 9/19/24.
//

import Foundation
import SwiftSyntax

public struct SwiftSyntaxModifier: SyntaxModifiable {
    public func modifySyntax(of parsedContent: SourceFileSyntax, filePath: URL) -> SourceFileSyntax {
        
        let codeExtractor = CodeExtractorService(viewMode: .all)
        codeExtractor.walk(parsedContent) // Initiate iteration of the syntax tree
        
        var closureReplacement: [ClosureExprSyntax: ClosureExprSyntax] = [:] // Dictionary to handle the unmodified and modified code
                                 
        for closure in codeExtractor.closureNodes { // Iterating capture closure nodes that hold the code and adding the profiling logic
            let inserter = TimingCodeInserter()
            let newClosure = inserter.visit(closure).as(ClosureExprSyntax.self)! // Adding the profiling code
            closureReplacement[closure] = newClosure // Maintain hashmap of old code and new code
        }
        // Service that replaces old code with new code
        let replacer = ClosureReplacer(closureReplacement: closureReplacement)
        let newContent = replacer.visit(parsedContent).as(SourceFileSyntax.self)!
        
        // Returning in abstracted type for merging to parent syntax tree
        return newContent
    }
}
