//
//  File.swift
//  detectlatency
//
//  Created by Rachit Prajapati on 9/19/24.
//

import Foundation
import SwiftSyntax

// Interface to handle writing on Swift files 
public protocol FileWriteable {
    func writeModifiedCodeToSourceFile(_ modifiedContent: SourceFileSyntax, to url: URL)
}
