//
//  SwiftFileWriter.swift
//  detectlatency
//
//  Created by Rachit Prajapati on 9/19/24.
//

import Foundation
import SwiftSyntax

public struct SwiftFileWriter: FileWriteable {
    public func writeModifiedCodeToSourceFile(_ modifiedContent: SwiftSyntax.SourceFileSyntax, to url: URL) {
        let modifiedSourceCode = modifiedContent.description // Fetching the string content of the modified code present as a syntax tree
        
        do {
            try modifiedSourceCode.write(to: url, atomically: true, encoding: .utf8) // write back to the respective swift file
            print("Successfully added profiled code")
        } catch let writeError {
            // Handle error
            print("Error writing file: \(writeError.localizedDescription)")
        }
    }
    
    
}
