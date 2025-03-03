//
//  Callgraphbuilder.swift
//  callgraphbuilder
//
//  Created by Rachit Prajapati on 1/16/25.
//

import SwiftSyntax
import SwiftParser
import Foundation
import OrderedCollections // Ordered hashmap to maintain order of called methods

// Service that handles generation of Call graph
class CallGraphBuilder {
    var callGraph = OrderedDictionary<String, [String]>() // Stores the call graph: function -> [called functions]
    
    private var unresolvedFunctions: [String] = [] // Functions that need to be resolved
    private var visitedFunctions: [String] = [] // Functions that have been resolved
    private var objectTypes: [String: String] = [:] // Tracks variable -> type relationships
    
    // SwiftUI UI Views list
    private let interactiveViewsList: Set<String> = ["Button", "contextMenu", "Slider", "NavigationLink" ]
    
    // SwiftUI UI View modifier list
    private let interactiveViewModifiersList: Set<String> = ["onTapGesture", "onChange", "onDrag", "onDelete", "destructive"]
    
    
    // Entry point to build the call graph
    func buildGraph(from filePath: String, in codebasePaths: [String]) {
//        print("[buildGraph] Starting with file: \(filePath)")
//        print("[buildGraph] Codebase files: \(codebasePaths)")
        
        // Enqueue all functions from the initial file (e.g., ContentView.swift)
        enqueueFunctions(from: filePath)
    
        // Process unresolved functions until there are none left
        while !unresolvedFunctions.isEmpty {
            let function = unresolvedFunctions.removeFirst()
            // Attempt to resolve each unresolved function
//            print("[buildGraph] Resolving function: \(function)")
            resolveFunction(function, in: codebasePaths)
        }
    }
    
    // Enqueues functions found in the given file
    private func enqueueFunctions(from filePath: String) {
        do {
            let fileContents = try String.init(contentsOfFile: filePath, encoding: .utf8)
            let processedFileContent = fileContents.trimmingCharacters(in: .whitespacesAndNewlines)
            let parsedContent = Parser.parse(source: processedFileContent)
            
            let visitor = UIElementDetector(interactiveViewsList: interactiveViewsList, interactiveViewModifiersList: interactiveViewModifiersList)
            visitor.walk(parsedContent)
            
            
            for function in visitor.collectedFunctions {
                callGraph[function] = []
                unresolvedFunctions.append(function)
            }
        } catch {
            print("Callgraphbuilder.swift: Error processing file for gathering functions under SwiftUI Elements to enqueue, \(error.localizedDescription) ")
        }
    }
    
    
    // Class method that visits the codebase to locate the unresolved function and collects other functions if called inside it. 
    private func resolveFunction(_ functionName: String, in codebasePaths: [String]) {
        // Skip if the function has already been resolved
        if visitedFunctions.contains(functionName) {
//            print("[resolveFunction] Skipping already visited function: \(functionName)")
            return
        }
        // filter out the function name, if it's object's method e.g AuthService.func2() -> func2()
        let functionName = String(describing: functionName.split(separator: ".").last ?? "")
        visitedFunctions.append(functionName)
//        print("[resolveFunction] Resolving function: \(functionName)")
        
        var found = false
        
        for path in codebasePaths {
            do {
                let fileContents = try String(contentsOfFile: path, encoding: .utf8)
                let processedFileContent = fileContents.trimmingCharacters(in: .whitespacesAndNewlines)
                let parsedContent = Parser.parse(source: processedFileContent)
                
                let visitor = FunctionResolver(targetFunction: functionName, objectTypes: objectTypes, filePath: URL(fileURLWithPath: path))
                visitor.walk(parsedContent)
                
                if let (calledFunctions, objects) = visitor.collectedData {
                    found = true
//                    print("[resolveFunction] Found \(functionName) in \(path): Calls: \(calledFunctions), Objects: \(objects)")
                    
                    // Filter out object instantiations like `AuthService`
                    let filteredCalls = calledFunctions.filter { !$0.matchesObjectType(objects) }
                    callGraph[functionName] = filteredCalls
                    objectTypes.merge(objects, uniquingKeysWith: { $1 })
                    
                    // Recursively resolve nested functions
                    for funcCall in filteredCalls where !visitedFunctions.contains(funcCall) {
//                        print("[resolveFunction] Adding unresolved function: \(funcCall)")
                        unresolvedFunctions.append(funcCall)
                    }
                    return
                }
            } catch {
//                print("[resolveFunction] Error processing file \(path): \(error.localizedDescription)")
            }
        }
        
        if !found {
//            print("[resolveFunction] Function \(functionName) not found in codebase")
            callGraph[functionName] = []
        }
    }
}
