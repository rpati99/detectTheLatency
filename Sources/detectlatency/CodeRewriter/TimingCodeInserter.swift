import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftParser

public class TimingCodeInserter: SyntaxRewriter, AsyncInsertable {
    
    // Override the visit method for ClosureExprSyntax
    public override func visit(_ node: ClosureExprSyntax) -> ExprSyntax {
        
        // Check if the closure contains async code like Task or an escaping closure
        let isAsyncOrEscaping = detectAsyncCode(node)
        
        if isAsyncOrEscaping {
//            var closureIndex = 0
//            // Traverse the closure's statements to find any Task block
//            var modifiedStatements = CodeBlockItemListSyntax { }
//            
//            for statement in node.statements {
//                
//                // Detect if the statement contains a Task block
//                if let taskCall = statement.item.as(FunctionCallExprSyntax.self),
//                   let taskName = taskCall.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text,
//                   taskName == "Task" {
//                    // We have found a Task block, so now insert profiling inside the Task's trailing closure
//                    if let taskClosure = taskCall.trailingClosure {
//                        let updatedTaskClosure = insertProfilingIntoTaskClosure(taskClosure)
//                        let updatedTaskCall = ExprSyntax(taskCall.with(\.trailingClosure, updatedTaskClosure)) // Fix: Wrap FunctionCallExprSyntax as ExprSyntax
//                        let updatedStatement = statement.with(\.item, updatedTaskCall.as(CodeBlockItemSyntax.Item.self)!)
//                        modifiedStatements.append(updatedStatement)
//                        continue
//                    }
//                }
//                
//                // Handle escaping closures
//                if let functionCall = statement.item.as(FunctionCallExprSyntax.self), hasEscapingClosure(functionCall) {
//                    // Insert profiling for escaping closures and return the resulting code block
//                    let updatedFunctionCallBlock = insertProfilingIntoEscapingClosures(functionCall, closureIndex: &closureIndex)
//                    
//                    // Convert the returned CodeBlockSyntax into a sequence of CodeBlockItemSyntax
//                    let updatedStatements: [CodeBlockItemSyntax] = updatedFunctionCallBlock.statements.map { stmt in
//                        stmt.as(CodeBlockItemSyntax.self)!
//                    }
//                    
//                    // Append all updated statements to the modifiedStatements list
//                    modifiedStatements.append(contentsOf: updatedStatements)
//                    continue
//                }
//                
//                // If no special cases (Task or Escaping closure), add the original statement
//                modifiedStatements.append(statement)
//            }
//            
//            return node.with(\.statements, modifiedStatements).as(ExprSyntax.self)!
            return ExprSyntax.init(node)
        } else {
            var closureIndex = 0
            var modifiedStatements = CodeBlockItemListSyntax { }
            for statement in node.statements {
                // Handle nested closures at any depth (inside any declared scope)
                let nestedAsyncCode = traverseAndDetectNestedScopes(statement.item.as(Syntax.self)!, closureIndex: &closureIndex)
                if let updatedClosure = nestedAsyncCode.as(ClosureExprSyntax.self) {
                    print("Updated closure is \n\(updatedClosure.description)")
                    let nestedStatement = statement.with(\.item, .expr(ExprSyntax(updatedClosure)))
                    modifiedStatements.append(nestedStatement)
                    continue
                }
            }
            
   
//             //Handle non-async and non-escaping closures: Insert profiling for all other cases
//            let timingCode = """
//                        
//                            let startTime = DispatchTime.now()
//                            defer {
//                                let endTime = DispatchTime.now()
//                                let timeInNanoSec = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
//                                let timeInSec = Double(timeInNanoSec) / 1_000_000_000
//                                debugPrint(timeInSec)
//                            }
//                        """
//            
//            // Parsing code above to build syntax tree
//            let timingCodeStatement = Parser.parse(source: timingCode).statements
//            modifiedStatements.append(contentsOf: timingCodeStatement)
//            
//            // Appending the existing code under closure
//            for statement in node.statements {
//                modifiedStatements.append(statement)
//            }
//            
//            // Replacing old code with new code that contains profiling code
//            let newBody = node.with(\.statements, modifiedStatements)
//            return ExprSyntax.init(newBody)
            return ExprSyntax.init(node)
        }
    }
    
    
    private func traverseAndDetectNestedScopes(_ item: Syntax, closureIndex: inout Int) -> Syntax {
        var modifiedSyntax = item

        // Use `.children(viewMode:)` to iterate over direct children of the item
        item.children(viewMode: .sourceAccurate).forEach { child in
            // Traverse further to get nested closures or async blocks
            child.children(viewMode: .sourceAccurate).forEach { descendant in

                // Check if the descendant is a CodeBlockSyntax to look for further nested statements
                if let codeBlock = descendant.as(CodeBlockSyntax.self) { // for accessing the code
                
                    var updatedStatements = CodeBlockItemListSyntax { }

                    // Traverse each statement inside the CodeBlockSyntax
                    for statement in codeBlock.statements {
                        // Recurse into each statement to look for async code (Tasks) or escaping closures
                        let traversedStatement = traverseAndDetectNestedScopes(Syntax(statement), closureIndex: &closureIndex)
                       
                        if let taskCall =  findTaskExpr(in: traversedStatement) {
                           
                            if let taskClosure = taskCall.trailingClosure {
                                let updatedTaskClosure = insertProfilingIntoTaskClosure(taskClosure)
                                let updatedTaskCall = taskCall.with(\.trailingClosure, updatedTaskClosure)

                                // Wrap the updated Task call in a CodeBlockItemSyntax and add it to updatedStatements
                                // TODO:_ FIX logic here since whole codeblockitem is being replaced with only mutated functionCallExprSyntax
                                // to retain the code 
                                let updatedStatement = statement.with(\.item, .expr(ExprSyntax(updatedTaskCall)))
                               
                            
                                updatedStatements.append(updatedStatement)
                                continue
                            }
                        }
                        
                        // Handle escaping closures inside the statements
                        if let functionCall = findFunctionCallExpr(in: traversedStatement), hasEscapingClosure(functionCall) {
                            let updatedFunctionCallBlock = insertProfilingIntoEscapingClosures(functionCall, closureIndex: &closureIndex)
                            
                            // Convert the returned CodeBlockSyntax into a sequence of CodeBlockItemSyntax
                            let functionCallStatements: [CodeBlockItemSyntax] = updatedFunctionCallBlock.statements.compactMap { stmt in
                                stmt.as(CodeBlockItemSyntax.self)
                            }

                            // Append all updated statements to the updatedStatements list
                            updatedStatements.append(contentsOf: functionCallStatements)
                            continue
                        }

                        // Append the traversed statement if no modifications are necessary
                        if let updatedStatement = traversedStatement.as(CodeBlockItemSyntax.self) {
                            updatedStatements.append(updatedStatement)
                        } else {
                            updatedStatements.append(statement)
                        }
                    }
                    
                    

                    // Create a new CodeBlockSyntax with the updated statements
                    let updatedCodeBlock = CodeBlockSyntax {
                        for statement in updatedStatements {
                            statement
                        }
                    }
                    
                

                    // Update the modifiedSyntax with the new CodeBlockSyntax
                    modifiedSyntax = Syntax(updatedCodeBlock)

                }
            }
        }
        return modifiedSyntax
    }
    


    // Helper function to find FunctionCallExprSyntax in a given Syntax node
    private func findFunctionCallExpr(in syntax: Syntax) -> FunctionCallExprSyntax? {
        if let functionCall = syntax.as(FunctionCallExprSyntax.self) {
            return functionCall
        }

        for child in syntax.children(viewMode: .sourceAccurate) {
            if let functionCall = findFunctionCallExpr(in: child) {
                return functionCall
            }
        }

        return nil
    }

    // Helper function to find Task in a given Syntax node
    private func  findTaskExpr(in syntax: Syntax) -> FunctionCallExprSyntax? {
        if let taskCall = syntax.as(FunctionCallExprSyntax.self),
           let taskName = taskCall.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text,
           taskName == "Task" {
            return taskCall
        }

        for child in syntax.children(viewMode: .sourceAccurate) {
            if let taskCall = findTaskExpr(in: child) {
                return taskCall
            }
        }

        return nil
    }
    



    private func addProfilingCodeToNestedClosure(_ closure: ClosureExprSyntax) -> ClosureExprSyntax {
        // Standard profiling code to insert inside the nested closure
        let profilingCode = """
            let nestedStartTime = DispatchTime.now()
            defer {
                let nestedEndTime = DispatchTime.now()
                let nestedTimeInNanoSec = nestedEndTime.uptimeNanoseconds - nestedStartTime.uptimeNanoseconds
                let nestedTimeInSec = Double(nestedTimeInNanoSec) / 1_000_000_000
                debugPrint("Nested closure took \\(nestedTimeInSec) seconds")
            }
        """

        let profilingCodeStatements = Parser.parse(source: profilingCode).statements
        var newStatements: CodeBlockItemListSyntax = profilingCodeStatements

        for statement in closure.statements {
            newStatements.append(statement)
        }

        return closure.with(\.statements, newStatements)
    }

    
    public func detectAsyncCode(_ node: ClosureExprSyntax) -> Bool {
        return node.statements.contains { statement in
            if let taskCall = statement.item.as(FunctionCallExprSyntax.self),
               let taskName = taskCall.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text,
               taskName == "Task" {
                return true
            }
            
            if let functionCall = statement.item.as(FunctionCallExprSyntax.self), hasEscapingClosure(functionCall) {
                return true
            }
            
            return false
        }
    }
    
    public func hasEscapingClosure(_ functionCall: FunctionCallExprSyntax) -> Bool {
        // Check if the function has either labeled closures in its arguments or a trailing closure
        let hasLabeledClosure = functionCall.arguments.contains { argument in
            argument.expression.as(ClosureExprSyntax.self) != nil
        }
        let hasTrailingClosure = functionCall.trailingClosure != nil
        return hasLabeledClosure || hasTrailingClosure
    }
    
    
    // Insert profiling code inside the Task block’s trailing closure
    public func insertProfilingIntoTaskClosure(_ closure: ClosureExprSyntax) -> ClosureExprSyntax {
        // The profiling code to insert
        let profilingCode = """
        
            let startTime = DispatchTime.now()
            defer {
                let endTime = DispatchTime.now()
                let timeInNanoSec = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
                let timeInSec = Double(timeInNanoSec) / 1_000_000_000
                debugPrint("Async Task took \\(timeInSec) seconds")
            }
        """
        
        // Parse the profiling code into syntax
        let profilingCodeStatements = Parser.parse(source: profilingCode).statements
        
        // Insert the profiling code at the beginning of the Task block's trailing closure
        var updatedStatements: CodeBlockItemListSyntax = profilingCodeStatements
        for statement in closure.statements {
            updatedStatements.append(statement)
        }
        
        // Return the closure with the profiling code added at the beginning
        return closure.with(\.statements, updatedStatements)
    }
    
    
    public func insertProfilingIntoEscapingClosures(_ functionCall: FunctionCallExprSyntax, closureIndex: inout Int) -> CodeBlockSyntax {
        // Generate start time code (to be placed before the closure)
        let startTimeVarName = "startTime\(closureIndex)"
        closureIndex += 1 // Increment the closure index for the next closure
        
        let startTimeCode = """
           
               let \(startTimeVarName) = DispatchTime.now()
           """
        
        // Parse the start time code into syntax statements
        let startTimeCodeStatements = Parser.parse(source: startTimeCode).statements
        
        // Handle labeled closures (closure in function arguments)
        let updatedArguments = functionCall.arguments.map { argument -> LabeledExprSyntax in
            if let closure = argument.expression.as(ClosureExprSyntax.self) {
                let updatedClosure = insertProfilingIntoEscapingClosure(closure, startTimeVarName: startTimeVarName)
                return argument.with(\.expression, ExprSyntax(updatedClosure))
            }
            return argument
        }
        
        // Handle the trailing closure separately if it exists
        var updatedFunctionCall = functionCall.with(\.arguments, LabeledExprListSyntax(updatedArguments))
        
        if let trailingClosure = functionCall.trailingClosure {
            let updatedTrailingClosure = insertProfilingIntoEscapingClosure(trailingClosure, startTimeVarName: startTimeVarName)
            updatedFunctionCall = updatedFunctionCall.with(\.trailingClosure, updatedTrailingClosure)
        }
        
        // Create a new CodeBlockItemListSyntax to hold both the startTime code and the function call
        var updatedStatements: CodeBlockItemListSyntax = startTimeCodeStatements
        
        // Add the updated function call into the new statements (to make it part of the same block)
        updatedStatements.append(CodeBlockItemSyntax(item: .expr(ExprSyntax(updatedFunctionCall))))
        
        // Wrap the new statements in a closure or code block as needed
        let finalFunctionCall = CodeBlockSyntax {
            for statement in updatedStatements {
                statement
            }
        }
        
        // Return the modified function call with the profiling start time added
        return finalFunctionCall
    }
    
    public func insertProfilingIntoEscapingClosure(_ closure: ClosureExprSyntax, startTimeVarName: String) -> ClosureExprSyntax {
        // Profiling code to insert in the defer block inside the closure
        let deferCode = """
        
            defer {
                let endTime = DispatchTime.now()
                let timeInNanoSec = endTime.uptimeNanoseconds - \(String(describing: startTimeVarName)).uptimeNanoseconds
                let timeInSec = Double(timeInNanoSec) / 1_000_000_000
                debugPrint("Escaping closure took \\(timeInSec) seconds")
            }
        """
        
        let deferCodeStatements = Parser.parse(source: deferCode).statements
        
        // Append the defer block to the closure's body
        var updatedStatements: CodeBlockItemListSyntax = deferCodeStatements
        for statement in closure.statements {
            updatedStatements.append(statement)
        }
        
        // Return the updated closure with the defer block added
        return closure.with(\.statements, updatedStatements)
    }
    
}


