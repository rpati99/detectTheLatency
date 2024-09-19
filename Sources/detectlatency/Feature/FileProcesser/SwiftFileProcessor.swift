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
    
    public func process(files: [URL]) {
        files.forEach { fileURL in
            do {
                let fileContents = try String.init(contentsOf: fileURL, encoding: .utf8)
                let processedFileContent = fileContents.trimmingCharacters(in: .whitespacesAndNewlines)
                let parsedContent = Parser.parse(source: processedFileContent)
                
                let modifyContent = syntaxService.modifySyntax(of: parsedContent, filePath: fileURL)
                
                writerService.writeModifiedCodeToSourceFile(modifyContent, to: fileURL)
            
            } catch let fileProcessingError {
                debugPrint("Error:- Couldn't process files \(fileProcessingError.localizedDescription)")
            }
        }
//        let fileContents: String
//
//        do {
//            fileContents = try String.init(contentsOf: fileURL, encoding: .utf8)
//            //  debugPrint(fileContents.trimmingCharacters(in: .whitespacesAndNewlines))
//            let processedFileContent = fileContents.trimmingCharacters(in: .whitespacesAndNewlines)
//
//            // Declaring parser
//            let parsedContent = Parser.parse(source: processedFileContent)
//
//            applyCodeExtractorService(parsedContent: parsedContent, filepath: fileURL)
//
//
//
//        } catch let error {
//            print("Error processing file contents \(error.localizedDescription)")
//        }
    }
}
