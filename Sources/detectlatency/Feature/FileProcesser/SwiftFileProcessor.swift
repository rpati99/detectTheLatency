//
//  SwiftFileProcessor.swift
//  detectlatency
//
//  Created by Rachit Prajapati on 9/19/24.
//

import Foundation
import SwiftSyntax
import SwiftParser


public struct SwiftFileProcessor : FileProcessable {
    
    private let syntaxService: SwiftSyntaxModifier
    private let writerService: SwiftFileWriter
    
    init(syntaxService: SwiftSyntaxModifier, writerService: SwiftFileWriter) {
        self.syntaxService = syntaxService
        self.writerService = writerService
    }
    
    public func process(files: [URL]) { // The input is the list of Swift files
        
        files.forEach { fileURL in
            initiateDetectLatency(fileURL) // Perform operation
        }
    }
    
    private func initiateDetectLatency(_ url: URL) {
        do {
            let fileContents = try String.init(contentsOf: url, encoding: .utf8) // Step 1. Fetching the code of Swift file
            let processedFileContent = fileContents.trimmingCharacters(in: .whitespacesAndNewlines) // Step 2. Formatting the content
            let parsedContent = Parser.parse(source: processedFileContent) // Step 3. Perform parsing of the input Swift code
            print("SYNTAX TREE BELOW")
            dump(parsedContent)
            // Step 4. Detect the SwiftUI UI components, inject the profiling code and fetch back the modified code as form of SourceFileSyntax
            let modifyContent = syntaxService.modifySyntax(of: parsedContent, filePath: url)

            
            // Step 5. Writing back the new code (in form of SourceFileSyntax) in the respective .swift file
            writerService.writeModifiedCodeToSourceFile(modifyContent, to: url)
        } catch let fileProcessingError {
            // Handle Error
            debugPrint("Error:- Couldn't process files \(fileProcessingError.localizedDescription)")
        }
    }
}
