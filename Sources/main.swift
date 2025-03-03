//
//  main.swift
//  detectlatency
//
//  Created by Rachit Prajapati on 9/19/24.
//

import Foundation

// GATEWAY of package which performs setup to profile code present inside interactive elements in SwiftUI application. 
func main() {
    // Get project path from command-line arguments
    guard CommandLine.arguments.count > 1 else {
        print("Usage: callgraphbuilder <path-to-xcode-project>")
        return
    }
    
    let projectPath = CommandLine.arguments[1]
    print("Processing Xcode project at: \(projectPath)") // log


    // CALLGRAPBUILDER module
    // Performs setup to create output to view profiling data of interactive code
    let swiftFiles = CallgraphGenApplication.collectSwiftFiles(from: projectPath)
    
    if swiftFiles.isEmpty {
        print("No Swift files found in the provided project directory.") // log
    } else {
        print("Found \(swiftFiles.count) Swift files. Processing...") // log
        CallgraphGenApplication.processSwiftFiles(swiftFiles, path: projectPath)
    }
    
    
    // DETECTLATENCY MODULE
    // Performs profiling setup under interactive UI Elements. 
    let syntaxModifier = SwiftSyntaxModifier()
    let fileWriter = SwiftFileWriter()
    let fileProcessor = SwiftFileProcessor(syntaxService: syntaxModifier, writerService: fileWriter)
    let fileFinder = SwiftFileFinder()

    let application = Application(fileFinder: fileFinder, fileProcessor: fileProcessor, fileWriter: fileWriter)

    // Run detectlatency
    application.run(with: CommandLine.arguments)

    
}

// Call the main function
main()

