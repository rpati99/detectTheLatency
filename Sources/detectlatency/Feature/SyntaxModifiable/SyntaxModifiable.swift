//
//  SyntaxModifiable.swift
//  detectlatency
//
//  Created by Rachit Prajapati on 9/19/24.
//

import Foundation
import SwiftSyntax

// Interface to handle modification of code inside Swift files 
public protocol SyntaxModifiable {
    func modifySyntax(of parsedContent: SourceFileSyntax, filePath: URL) -> SourceFileSyntax
}
 
