import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftParser

public final class TimingCodeInserter: SyntaxRewriter {
    
    
    // Override the visit method for ClosureExprSyntax
    public override func visit(_ node: ClosureExprSyntax) -> ExprSyntax {
       
        
        // Check if the closure contains async code like Task or an escaping closure
        let isAsyncOrEscaping = node.statements.contains { statement in
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
        
        
        if isAsyncOrEscaping {
            var closureIndex = 0
            // Traverse the closure's statements to find any Task block
            var modifiedStatements = CodeBlockItemListSyntax { }

            for statement in node.statements {
                
                // Detect if the statement contains a Task block
                if let taskCall = statement.item.as(FunctionCallExprSyntax.self),
                   let taskName = taskCall.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text,
                   taskName == "Task" {
                    // We have found a Task block, so now insert profiling inside the Task's trailing closure
                    if let taskClosure = taskCall.trailingClosure {
                        let updatedTaskClosure = insertProfilingIntoTaskClosure(taskClosure)
                        let updatedTaskCall = ExprSyntax(taskCall.with(\.trailingClosure, updatedTaskClosure)) // Fix: Wrap FunctionCallExprSyntax as ExprSyntax
                        let updatedStatement = statement.with(\.item, updatedTaskCall.as(CodeBlockItemSyntax.Item.self)!)
                        modifiedStatements.append(updatedStatement)
                        continue
                    }
                }
                
                // Handle escaping closures
                if let functionCall = statement.item.as(FunctionCallExprSyntax.self), hasEscapingClosure(functionCall) {
                    // Insert profiling for escaping closures and return the resulting code block
                    let updatedFunctionCallBlock = insertProfilingIntoEscapingClosures(functionCall, closureIndex: &closureIndex)
                    
                    // Convert the returned CodeBlockSyntax into a sequence of CodeBlockItemSyntax
                    let updatedStatements: [CodeBlockItemSyntax] = updatedFunctionCallBlock.statements.map { stmt in
                        stmt.as(CodeBlockItemSyntax.self)!
                    }

                    // Append all updated statements to the modifiedStatements list
                    modifiedStatements.append(contentsOf: updatedStatements)
                    continue
                }
                
                // If no special cases (Task or Escaping closure), add the original statement
                modifiedStatements.append(statement)
            }

            return node.with(\.statements, modifiedStatements).as(ExprSyntax.self)!
        } else {
            // Handle non-async and non-escaping closures: Insert profiling for all other cases
            let timingCode = """
                        
                            let startTime = DispatchTime.now()
                            defer {
                                let endTime = DispatchTime.now()
                                let timeInNanoSec = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
                                let timeInSec = Double(timeInNanoSec) / 1_000_000_000
                                debugPrint(timeInSec)
                            }
                        """
            
            // Parsing code above to build syntax tree
            let timingCodeStatement = Parser.parse(source: timingCode).statements
            var newStatements: CodeBlockItemListSyntax = timingCodeStatement
            
            // Appending the existing code under closure
            for statement in node.statements {
                newStatements.append(statement)
            }
            
            // Replacing old code with new code that contains profiling code
            let newBody = node.with(\.statements, newStatements)
            return ExprSyntax.init(newBody)
        }
    }
    
    private func hasEscapingClosure(_ functionCall: FunctionCallExprSyntax) -> Bool {
        // Check if the function has either labeled closures in its arguments or a trailing closure
        let hasLabeledClosure = functionCall.arguments.contains { argument in
            argument.expression.as(ClosureExprSyntax.self) != nil
        }
        let hasTrailingClosure = functionCall.trailingClosure != nil
        return hasLabeledClosure || hasTrailingClosure
    }
    
    
    // Insert profiling code inside the Task block’s trailing closure
    private func insertProfilingIntoTaskClosure(_ closure: ClosureExprSyntax) -> ClosureExprSyntax {
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
    
    
    private func insertProfilingIntoEscapingClosures(_ functionCall: FunctionCallExprSyntax, closureIndex: inout Int) -> CodeBlockSyntax {
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
    
    private func insertProfilingIntoEscapingClosure(_ closure: ClosureExprSyntax, startTimeVarName: String) -> ClosureExprSyntax {
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
