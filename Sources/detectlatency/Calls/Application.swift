//
//  Applicaton.swift
//  detectlatency
//
//  Created by Rachit Prajapati on 9/19/24.
//


import Foundation
import SwiftSyntax

// Parent service of detectlatency module of that performs profiling setup for interactive UI elements.
public class Application {
    private let fileFinder: SwiftFileFinder
    private let fileProcessor: SwiftFileProcessor
    private let fileWriter: SwiftFileWriter
    
    init(fileFinder: SwiftFileFinder, fileProcessor: SwiftFileProcessor, fileWriter: SwiftFileWriter) {
        self.fileFinder = fileFinder
        self.fileProcessor = fileProcessor
        self.fileWriter = fileWriter
    }
    
    public func run(with arguments: [String]) {
        guard arguments.count > 1 else {
            print("Usage: detectlatency <path-to-xcode-project>")
            return
        }
        
        let swiftFiles = fileFinder.findSwiftFiles(directory: arguments[1]) // hold the files that are of .swift format
        fileProcessor.process(files: swiftFiles) // Perform setup of profiling under UI elements
    }
}

