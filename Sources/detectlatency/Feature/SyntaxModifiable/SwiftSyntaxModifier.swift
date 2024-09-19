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
        codeExtractor.walk(parsedContent)
        
        var closureReplacement: [ClosureExprSyntax: ClosureExprSyntax] = [:]
                                 
        for closure in codeExtractor.closureNodes {
            let inserter = TimingCodeInserter()
            let newClosure = inserter.visit(closure).as(ClosureExprSyntax.self)!
            closureReplacement[closure] = newClosure
        }
      
        let replacer = ClosureReplacer(closureReplacement: closureReplacement)
        let newContent = replacer.visit(parsedContent).as(SourceFileSyntax.self)!
        return newContent
    }
}
