//
//  FunctionResolver.swift
//  callgraphbuilder
//
//  Created by Rachit Prajapati on 1/22/25.
//

import Foundation
import SwiftSyntax
import SwiftParser

// Service that detects functions 
public class FunctionResolver: SyntaxVisitor {
    let targetFunction: String // function to be resolved
    var collectedData: (
        [String],
        [String: String]
    )? // ([calledFunctions], [objectName: objectType])
    private var calledFunctions: [String] = [] // list of functions fetched
    private var objectTypes: [String: String] = [:] // list of functons fetched as object .
    let filePath: URL // file path of code
    
    // Global set to track modified functions
    nonisolated(unsafe) static var modifiedFunctions = Set<String>()
    
    init(targetFunction: String, objectTypes: [String: String], filePath: URL) {
        self.targetFunction = targetFunction
        self.objectTypes = objectTypes
        self.filePath = filePath
        super.init(viewMode: .sourceAccurate)
    }
    
    
    // for functions that are declared top level
    public override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        let isStatic = node.modifiers.contains { $0.name.text == "static" }
        
        if node.name.text == targetFunction || isStatic {
            if FunctionResolver.modifiedFunctions.contains(node.name.text){
                return .visitChildren
            }
            applyRewriter(to: node, name: node.name.text)
        }
        
        if node.name.text == targetFunction {
            let visitor = FunctionBodyVisitor(objectTypes: objectTypes)
            if let body = node.body {
                visitor.walk(body)
                //                print("[FunctionResolver] \(targetFunction): Collected calls: \(visitor.calledFunctions), Objects: \(visitor.objectTypes)")
                collectedData = (visitor.calledFunctions, visitor.objectTypes)
            }
            return .skipChildren
        }
        return .visitChildren
        
        
    }
    
    
    // for functions that are declared under class
    public override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        //        print("[FunctionResolver] Visiting class: \(node.name.text)")
        for member in node.memberBlock.members {
         
            if let method = member.decl.as(FunctionDeclSyntax.self) {
                let isStatic = method.modifiers.contains { $0.name.text == "static" }
                if method.name.text == targetFunction || isStatic {
                    if FunctionResolver.modifiedFunctions.contains(method.name.text) {
                        continue
                    }
                    applyRewriter(to: method, name: method.name.text)
                }
            }
            
            if let method = member.decl.as(FunctionDeclSyntax.self),
               method.name.text == targetFunction {
                
                //                print("[FunctionResolver] Found method \(targetFunction) in class \(node.name.text)")
                let visitor = FunctionBodyVisitor(objectTypes: objectTypes)
                if let body = method.body {
                    visitor.walk(body)
                    collectedData = (
                        visitor.calledFunctions,
                        visitor.objectTypes
                    )
                }
                return .skipChildren
            }
        }
        return .visitChildren
    }
    // Handle functions inside enums
    public override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        for member in node.memberBlock.members {
            if let method = member.decl.as(FunctionDeclSyntax.self) {
                let isStatic = method.modifiers.contains { $0.name.text == "static" }
                if method.name.text == targetFunction || isStatic {
                    if FunctionResolver.modifiedFunctions.contains(method.name.text) {
                        continue
                    }
                    applyRewriter(to: method, name: method.name.text)
                }
            }

        }
        return .visitChildren
    }
    
    
    // for functions that are declared inside structs
    public override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        // Visit methods in a struct declaration
        for member in node.memberBlock.members {
            if let method = member.decl.as(FunctionDeclSyntax.self) {
                let isStatic = method.modifiers.contains { $0.name.text == "static" }
                if method.name.text == targetFunction || isStatic {
                    if FunctionResolver.modifiedFunctions.contains(method.name.text) {
                        continue
                    }
                    applyRewriter(to: method, name: method.name.text)
                }
            }

            
            if let method = member.decl.as(FunctionDeclSyntax.self),
               method.name.text == targetFunction {
                //                print("[FunctionResolver] Found method \(targetFunction) in struct \(node.name.text)")
                let visitor = FunctionBodyVisitor(objectTypes: objectTypes)
                if let body = method.body {
                    visitor.walk(body)
                    collectedData = (
                        visitor.calledFunctions,
                        visitor.objectTypes
                    )
                }
                return .skipChildren
            }
        }
        return .visitChildren
    }
    
    // changes the old function code with new function code that contains the profiling injected code.
    private func applyRewriter(to functionNode: FunctionDeclSyntax, name: String) {
        if FunctionResolver.modifiedFunctions.contains(name) {
            return
        }

        // Service that handles injection of profiling code inside existing function code.
        let timingCodeInserter = MethodProfilingInserter(message: name)
        let modifiedNode = timingCodeInserter.visit(functionNode).as(FunctionDeclSyntax.self) ?? functionNode
        FunctionResolver.modifiedFunctions.insert(name)
        
        // Write back to the file
        writeModifiedFunction(modifiedNode)
    }
    
    // Writes the modified function back to the source file
    private func writeModifiedFunction(_ modifiedFunction: FunctionDeclSyntax) {
        do {
            // Read original file
            let fileContents = try String(contentsOf: filePath, encoding: .utf8)
            let parsedSyntax = Parser.parse(source: fileContents)
            
            // Replace function in the parsed syntax tree
            let rewriter = ReplaceFunctionRewriter(
                targetFunction: targetFunction,
                newFunction: modifiedFunction
            )
            let modifiedSyntaxTree = rewriter.visit(parsedSyntax)
      
            // Convert the modified syntax tree back to Swift source code
            let modifiedSource = modifiedSyntaxTree.description
            
            // Write the updated source code back to the file
            try modifiedSource
                .write(to: filePath, atomically: true, encoding: .utf8)
        } catch {
            print(
                "[Error] Failed to write updated file \(filePath.path): \(error.localizedDescription)"
            )
        }
    }
}

