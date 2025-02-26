//
//  CallgraphGenApplication.swift
//  callgraphbuilder
//
//  Created by Rachit Prajapati on 2/10/25.
//

import Foundation
import SwiftParser
import OrderedCollections

public class CallgraphGenApplication {
    
    // collects the Swift files from the provided codebase
    public static func collectSwiftFiles(from projectPath: String) -> [URL] {
        
        let fileManager = FileManager.default
        var swiftFiles: [URL] = [] // Storing Swift files
        
        if let enumerator = fileManager.enumerator(atPath: projectPath) {
            for case let file as String in enumerator {
                if file.hasSuffix(".swift") {
                    let fullPath = URL(filePath: projectPath).appendingPathComponent(file)
                    swiftFiles.append(fullPath)
                }
            }
        }
        
        return swiftFiles
    }
    
    // Process Swift files and build a call graph

    public static func processSwiftFiles(_ swiftFiles: [URL]) {
        // Convert file paths to strings for the CallGraphBuilder
        let filePaths = swiftFiles.map { $0.path }
        var processFilesThatContainUIElements = [URL]()
        
        for file in swiftFiles {
            if initiateFilteringToFindFirstFileThatContainsUIElements(filePath: file) {
                processFilesThatContainUIElements.append(file)
            }
        }
        
        // Generate the call graph
       var codebaseCallgraph =  Array<OrderedDictionary<String, [String]>>()
        for fileThatContainsUIElement in processFilesThatContainUIElements {
            let callGraphBuilder = CallGraphBuilder()
            callGraphBuilder.buildGraph(from: fileThatContainsUIElement.path(), in: filePaths)
            print("For file \(fileThatContainsUIElement.lastPathComponent)\n")
            print("Generated Call Graph:\n")
            codebaseCallgraph.append(callGraphBuilder.callGraph)
            print(codebaseCallgraph)
            for (function, calls) in callGraphBuilder.callGraph {
                
                print("Function: \(function)")
                for call in calls {
                    print("Calls: \(call)")
                }
            }
        }
    }
    
    // filters and collects file of Swift format from directory
    public static func initiateFilteringToFindFirstFileThatContainsUIElements(filePath: URL) -> Bool {
        do {
            let fileContents = try String.init(contentsOf: filePath, encoding: .utf8)
            let processedFileContent = fileContents.trimmingCharacters(in: .whitespacesAndNewlines)
            let parsedContent = Parser.parse(source: processedFileContent)
            let buttonIndicator = InteractiveElementFinder(viewMode: .sourceAccurate)
            buttonIndicator.walk(parsedContent)
            
            if buttonIndicator.containsInteractiveElement {
                return true
            } else {
                return false
            }
        } catch {
            print("Error processing finding the first to process that contains button \(error.localizedDescription)")
            return false
        }
    }
}

