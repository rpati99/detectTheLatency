//
//  SyntaxModifiable.swift
//  detectlatency
//
//  Created by Rachit Prajapati on 9/19/24.
//

import Foundation
import SwiftSyntax

public protocol SyntaxModifiable {
    func modifySyntax(of parsedContent: SourceFileSyntax, filePath: URL) -> SourceFileSyntax
}
