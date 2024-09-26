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
            // Traverse the closure's statements to find any Task block
            let modifiedStatements = node.statements.map { statement -> CodeBlockItemSyntax in
                
                // Detect if the statement contains a Task block
                if let taskCall = statement.item.as(FunctionCallExprSyntax.self),
                   let taskName = taskCall.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text,
                   taskName == "Task" {
                    // We have found a Task block, so now insert profiling inside the Task's trailing closure
                    
                    if let taskClosure = taskCall.trailingClosure {
                        let updatedTaskClosure = insertProfilingIntoTaskClosure(taskClosure)
                        let updatedTaskCall = ExprSyntax(taskCall.with(\.trailingClosure, updatedTaskClosure)) // Fix: Wrap FunctionCallExprSyntax as ExprSyntax
                        return statement.with(\.item,  updatedTaskCall.as(CodeBlockItemSyntax.Item.self)!)
                        
                    }
                }
                
                if let functionCall = statement.item.as(FunctionCallExprSyntax.self), hasEscapingClosure(functionCall) {
                    
                    print("FUNCTION CALL!!!!!! \n \(functionCall.description)")
                    let updatedFunctionCall = insertProfilingIntoEscapingClosures(functionCall)
                    return statement.with(\.item, .expr(ExprSyntax(updatedFunctionCall)))
                }
                
                return statement
                
            }
            
            
            return node.with(\.statements, CodeBlockItemListSyntax(modifiedStatements)).as(ExprSyntax.self)!
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
    
    
    
    // Insert profiling code inside escaping closures
    private func insertProfilingIntoEscapingClosures(_ functionCall: FunctionCallExprSyntax) -> FunctionCallExprSyntax {
        // Traverse the function's arguments and detect closures (labeled closures)
        let updatedArguments = functionCall.arguments.map { argument -> LabeledExprSyntax in
            if let closure = argument.expression.as(ClosureExprSyntax.self) {
                let updatedClosure = insertProfilingIntoEscapingClosure(closure)
                return argument.with(\.expression, ExprSyntax(updatedClosure))
            }
            return argument
        }
        
        // If there's a trailing closure (i.e., a closure declared without argument labels), insert profiling into it
        if let trailingClosure = functionCall.trailingClosure {
            let updatedTrailingClosure = insertProfilingIntoEscapingClosure(trailingClosure)
            return functionCall.with(\.trailingClosure, updatedTrailingClosure)
        }
        
        return functionCall.with(\.arguments, LabeledExprListSyntax(updatedArguments))
    }
    
    // Insert profiling code inside an escaping closure (used in function arguments or trailing closure)
    private func insertProfilingIntoEscapingClosure(_ closure: ClosureExprSyntax) -> ClosureExprSyntax {
        let profilingCode = """
           
               let startTime = DispatchTime.now()
               defer {
                   let endTime = DispatchTime.now()
                   let timeInNanoSec = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
                   let timeInSec = Double(timeInNanoSec) / 1_000_000_000
                   debugPrint("Escaping closure took \\(timeInSec) seconds")
               }
           """
        
        let profilingCodeStatements = Parser.parse(source: profilingCode).statements
        
        var updatedStatements: CodeBlockItemListSyntax = profilingCodeStatements
        for statement in closure.statements {
            updatedStatements.append(statement)
        }
        
        return closure.with(\.statements, updatedStatements)
    }


    
}
//import SwiftSyntax
//import SwiftSyntaxBuilder
//import SwiftParser
//
//public final class TimingCodeInserter: SyntaxRewriter {
//    
//    // Override the visit method for ClosureExprSyntax
//    public override func visit(_ node: ClosureExprSyntax) -> ExprSyntax {
//        
//        // Traverse the closure's statements to find any Task block
//        let modifiedStatements = node.statements.flatMap { statement -> [CodeBlockItemSyntax] in
//            // Insert profiling for all other closures
//            let profilingStatements = insertProfilingForAllClosures(statement)
//            
//            // Detect if the statement contains a Task block
//            if let taskCall = statement.item.as(FunctionCallExprSyntax.self),
//               let taskName = taskCall.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text,
//               taskName == "Task" {
//                // We have found a Task block, so now insert profiling inside the Task's trailing closure
//                if let taskClosure = taskCall.trailingClosure {
//                    let updatedTaskClosure = insertProfilingIntoTaskClosure(taskClosure)
//                    let updatedTaskCall = ExprSyntax(taskCall.with(\.trailingClosure, updatedTaskClosure)) // Fix: Wrap FunctionCallExprSyntax as ExprSyntax
//                    
//                    // Return the original statement + profiling statements
//                    return statement.with(\.item, updatedTaskCall.as(CodeBlockItemSyntax.Item.self)!)
//                }
//            }
//            
//            // Handle escaping closures
//            if let functionCall = statement.item.as(FunctionCallExprSyntax.self), hasEscapingClosure(functionCall) {
//                print("Escaping Function Call detected: \n \(functionCall.description)")
//                let updatedFunctionCall = insertProfilingIntoEscapingClosures(functionCall)
//                
//                // Return the original statement + profiling statements
//                return statement.with(\.item, .expr(ExprSyntax(updatedFunctionCall)))
//            }
//            
//            // If no Task block or escaping closure, return the profiling statements + the original statement
//            return profilingStatements
//        }
//        
//        return node.with(\.statements, CodeBlockItemListSyntax(modifiedStatements)).as(ExprSyntax.self)!
//    }
//
//    private func hasEscapingClosure(_ functionCall: FunctionCallExprSyntax) -> Bool {
//        // Check if the function has either labeled closures in its arguments or a trailing closure
//        let hasLabeledClosure = functionCall.arguments.contains { argument in
//            argument.expression.as(ClosureExprSyntax.self) != nil
//        }
//        let hasTrailingClosure = functionCall.trailingClosure != nil
//        return hasLabeledClosure || hasTrailingClosure
//    }
//    
//    // Insert profiling code inside the Task block’s trailing closure
//    private func insertProfilingIntoTaskClosure(_ closure: ClosureExprSyntax) -> ClosureExprSyntax {
//        // The profiling code to insert
//        let profilingCode = """
//        
//            let startTime = DispatchTime.now()
//            defer {
//                let endTime = DispatchTime.now()
//                let timeInNanoSec = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
//                let timeInSec = Double(timeInNanoSec) / 1_000_000_000
//                debugPrint("Async Task took \\(timeInSec) seconds")
//            }
//        """
//        
//        // Parse the profiling code into syntax
//        let profilingCodeStatements = Parser.parse(source: profilingCode).statements
//        
//        // Insert the profiling code at the beginning of the Task block's trailing closure
//        var updatedStatements: CodeBlockItemListSyntax = profilingCodeStatements
//        for statement in closure.statements {
//            updatedStatements.append(statement)
//        }
//        
//        // Return the closure with the profiling code added at the beginning
//        return closure.with(\.statements, updatedStatements)
//    }
//    
//    // Insert profiling code inside escaping closures
//    private func insertProfilingIntoEscapingClosures(_ functionCall: FunctionCallExprSyntax) -> FunctionCallExprSyntax {
//        // Traverse the function's arguments and detect closures (labeled closures)
//        let updatedArguments = functionCall.arguments.map { argument -> LabeledExprSyntax in
//            if let closure = argument.expression.as(ClosureExprSyntax.self) {
//                let updatedClosure = insertProfilingIntoEscapingClosure(closure)
//                return argument.with(\.expression, ExprSyntax(updatedClosure))
//            }
//            return argument
//        }
//        
//        // If there's a trailing closure (i.e., a closure declared without argument labels), insert profiling into it
//        if let trailingClosure = functionCall.trailingClosure {
//            let updatedTrailingClosure = insertProfilingIntoEscapingClosure(trailingClosure)
//            return functionCall.with(\.trailingClosure, updatedTrailingClosure)
//        }
//        
//        return functionCall.with(\.arguments, LabeledExprListSyntax(updatedArguments))
//    }
//    
//    // Insert profiling code inside an escaping closure (used in function arguments or trailing closure)
//    private func insertProfilingIntoEscapingClosure(_ closure: ClosureExprSyntax) -> ClosureExprSyntax {
//        let profilingCode = """
//           
//               let startTime = DispatchTime.now()
//               defer {
//                   let endTime = DispatchTime.now()
//                   let timeInNanoSec = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
//                   let timeInSec = Double(timeInNanoSec) / 1_000_000_000
//                   debugPrint("Escaping closure took \\(timeInSec) seconds")
//               }
//           """
//        
//        let profilingCodeStatements = Parser.parse(source: profilingCode).statements
//        
//        var updatedStatements: CodeBlockItemListSyntax = profilingCodeStatements
//        for statement in closure.statements {
//            updatedStatements.append(statement)
//        }
//        
//        return closure.with(\.statements, updatedStatements)
//    }
//    
//    // Insert profiling code for all other closures (non-async, non-escaping closures)
//    private func insertProfilingForAllClosures(_ statement: CodeBlockItemSyntax) -> [CodeBlockItemSyntax] {
//        let profilingCode = """
//            let startTime = DispatchTime.now()
//            defer {
//                let endTime = DispatchTime.now()
//                let timeInNanoSec = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
//                let timeInSec = Double(timeInNanoSec) / 1_000_000_000
//                debugPrint("Non-async closure took \\(timeInSec) seconds")
//            }
//        """
//        
//        // Parse the profiling code into a syntax tree
//        let parsedProfilingCode = Parser.parse(source: profilingCode).statements
//        
//        // Create an array to hold both profiling statements and the original statement
//        var updatedStatements: [CodeBlockItemSyntax] = parsedProfilingCode.map { $0 }
//        
//        // Append the original statement
//        updatedStatements.append(statement)
//        
//        return updatedStatements
//    }
//}
