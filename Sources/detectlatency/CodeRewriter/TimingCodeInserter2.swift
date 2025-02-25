import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftParser

public class TimingCodeInserter2: SyntaxRewriter {
    public override func visit(_ node: ClosureExprSyntax) -> ExprSyntax {
        var closureIndex = 0
        var modifiedStatements = CodeBlockItemListSyntax { }
        
        // Ensure profiling is inserted at the start
        let timingCode = """
        
        
            let startTime = DispatchTime.now()
            defer {
                let endTime = DispatchTime.now()
                let timeInNanoSec = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
                let timeInSec = Double(timeInNanoSec) / 1_000_000_000
                debugPrint("Sync execution took \\(timeInSec) seconds")
            }
        """
        
        let timingCodeStatements = Parser.parse(source: timingCode).statements
        modifiedStatements.append(contentsOf: timingCodeStatements)
        
        // Perform DFS traversal for top level statements
        for statement in node.statements {
            modifiedStatements.append(contentsOf: dfsInsertProfiling(statement, closureIndex: &closureIndex))
        }
        
        let newBody = node.with(\.statements, modifiedStatements)
        return ExprSyntax(newBody)
    }
    
    // DFS traversal to insert profiling at any nested level
    private func dfsInsertProfiling(_ statement: CodeBlockItemSyntax, closureIndex: inout Int) -> [CodeBlockItemSyntax] {
        var modifiedStatements: [CodeBlockItemSyntax] = []
        
        // Handle Task block
        if let taskCall = statement.item.as(FunctionCallExprSyntax.self),
           let taskName = taskCall.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text,
           taskName == "Task" {
            
            if let taskClosure = taskCall.trailingClosure {
                let updatedTaskClosure = insertProfilingIntoTaskClosure(taskClosure, closureIndex: &closureIndex)
                let updatedTaskCall = ExprSyntax(taskCall.with(\.trailingClosure, updatedTaskClosure))
                let updatedStatement = statement.with(\.item, updatedTaskCall.as(CodeBlockItemSyntax.Item.self)!)
                modifiedStatements.append(updatedStatement)
                return modifiedStatements
            }
        }
        
        // Handle Task.detached block
        if let functionCall = statement.item.as(FunctionCallExprSyntax.self),
           let taskDetachedCall = functionCall.calledExpression.as(MemberAccessExprSyntax.self),
           taskDetachedCall.declName.baseName.text == "detached" {
            
            if let taskClosure = functionCall.trailingClosure {
                let updatedTaskClosure = insertProfilingIntoTaskClosure(taskClosure, closureIndex: &closureIndex)
                let updatedTaskCall = ExprSyntax(functionCall.with(\.trailingClosure, updatedTaskClosure))
                let updatedStatement = statement.with(\.item, updatedTaskCall.as(CodeBlockItemSyntax.Item.self)!)
                modifiedStatements.append(updatedStatement)
                return modifiedStatements
            }
        }
        
        // Handle escaping closures in any order
        if let functionCall = statement.item.as(FunctionCallExprSyntax.self), hasEscapingClosure(functionCall) {
            let updatedFunctionCallBlock = insertProfilingIntoEscapingClosures(functionCall, closureIndex: &closureIndex)
            let updatedStatements = updatedFunctionCallBlock.statements.map { stmt in stmt.as(CodeBlockItemSyntax.self)! }
            modifiedStatements.append(contentsOf: updatedStatements)
            return modifiedStatements
        }
        // if statement
        if let ifStmt = statement.item.as(ExpressionStmtSyntax.self)?.expression.as(IfExprSyntax.self) {
            let updatedIf = processIf(ifStmt, closureIndex: &closureIndex)
            let updatedStatement = statement.with(\.item, .expr(ExprSyntax(updatedIf)))
            modifiedStatements.append(updatedStatement)
            return modifiedStatements
        }
        
        
        // for-in loop
        if let forStmt = statement.item.as(ForStmtSyntax.self) {
            let updatedFor = processForIn(forStmt, closureIndex: &closureIndex)
            let updatedStatement = statement.with(\.item, .stmt(StmtSyntax(updatedFor)))
            modifiedStatements.append(updatedStatement)
            return modifiedStatements
        }
        
        // while loop
        if let whileStmt = statement.item.as(WhileStmtSyntax.self) {
            let updatedWhile = processWhile(whileStmt, closureIndex: &closureIndex)
            let updatedStatement = statement.with(\.item, .stmt(StmtSyntax(updatedWhile)))
            modifiedStatements.append(updatedStatement)
            return modifiedStatements
        }
        
        // repeat-while loop
        if let repeatStmt = statement.item.as(RepeatStmtSyntax.self) {
            let updatedRepeat = processRepeatWhile(repeatStmt, closureIndex: &closureIndex)
            let updatedStatement = statement.with(\.item, .stmt(StmtSyntax(updatedRepeat)))
            modifiedStatements.append(updatedStatement)
            return modifiedStatements
        }
        
        
        
        // If no modification is needed, keep the original statement
        modifiedStatements.append(statement)
        return modifiedStatements
    }
    
    // Check for escaping closure
    public func hasEscapingClosure(_ functionCall: FunctionCallExprSyntax) -> Bool {
        let hasLabeledClosure = functionCall.arguments.contains { argument in
            argument.expression.as(ClosureExprSyntax.self) != nil
        }
        let hasTrailingClosure = functionCall.trailingClosure != nil
        return hasLabeledClosure || hasTrailingClosure
    }
    
    // Insert profiling code inside a Task or Task.detached block
    public func insertProfilingIntoTaskClosure(_ closure: ClosureExprSyntax, closureIndex: inout Int) -> ClosureExprSyntax {
        let profilingCode = """
        
        
            let startTime = DispatchTime.now()
            defer {
                let endTime = DispatchTime.now()
                let timeInNanoSec = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
                let timeInSec = Double(timeInNanoSec) / 1_000_000_000
                debugPrint("Async Task took \\(timeInSec) seconds")
            }
        """
        
        let profilingCodeStatements = Parser.parse(source: profilingCode).statements
        var updatedStatements: CodeBlockItemListSyntax = profilingCodeStatements
        
        // Apply DFS insertion inside task and task detached block for nested insertion
        for statement in closure.statements {
            updatedStatements.append(contentsOf: dfsInsertProfiling(statement, closureIndex: &closureIndex))
        }
        
        return closure.with(\.statements, updatedStatements)
    }
    
    // Insert first half of profiling code before start of escaping closure
    public func insertProfilingIntoEscapingClosures(_ functionCall: FunctionCallExprSyntax, closureIndex: inout Int) -> CodeBlockSyntax {
        let startTimeVarName = "startTime\(closureIndex)"
        closureIndex += 1
        
        let startTimeCode = """
           
               let \(startTimeVarName) = DispatchTime.now()
           """
        
        let startTimeCodeStatements = Parser.parse(source: startTimeCode).statements
        
        let updatedArguments = functionCall.arguments.map { argument -> LabeledExprSyntax in
            if let closure = argument.expression.as(ClosureExprSyntax.self) {
                let updatedClosure = insertProfilingIntoEscapingClosure(closure, startTimeVarName: startTimeVarName, closureIndex: &closureIndex)
                return argument.with(\.expression, ExprSyntax(updatedClosure))
            }
            return argument
        }
        
        var updatedFunctionCall = functionCall.with(\.arguments, LabeledExprListSyntax(updatedArguments))
        
        if let trailingClosure = functionCall.trailingClosure {
            let updatedTrailingClosure = insertProfilingIntoEscapingClosure(trailingClosure, startTimeVarName: startTimeVarName, closureIndex: &closureIndex)
            updatedFunctionCall = updatedFunctionCall.with(\.trailingClosure, updatedTrailingClosure)
        }
        
        var updatedStatements: CodeBlockItemListSyntax = startTimeCodeStatements
        updatedStatements.append(CodeBlockItemSyntax(item: .expr(ExprSyntax(updatedFunctionCall))))
        
        let finalFunctionCall = CodeBlockSyntax {
            for statement in updatedStatements {
                statement
            }
        }
        
        return finalFunctionCall
    }
    
    /// Insert second half of profiling inside escaping closure
    public func insertProfilingIntoEscapingClosure(_ closure: ClosureExprSyntax, startTimeVarName: String, closureIndex: inout Int) -> ClosureExprSyntax {
        let deferCode = """
        
            defer {
                let endTime = DispatchTime.now()
                let timeInNanoSec = endTime.uptimeNanoseconds - \(String(describing: startTimeVarName)).uptimeNanoseconds
                let timeInSec = Double(timeInNanoSec) / 1_000_000_000
                debugPrint("Escaping closure took \\(timeInSec) seconds")
            }
        """
        
        let deferCodeStatements = Parser.parse(source: deferCode).statements
        var updatedStatements: CodeBlockItemListSyntax = deferCodeStatements
        
        // Apply DFS for inside escping closure for nested insertion
        for statement in closure.statements {
            updatedStatements.append(contentsOf: dfsInsertProfiling(statement, closureIndex: &closureIndex))
        }
        
        return closure.with(\.statements, updatedStatements)
    }
    
    // handling conditional statement below
    private func processIf(_ ifStmt: IfExprSyntax, closureIndex: inout Int) -> IfExprSyntax {
        // Recurse into the 'then' block
        let updatedBody = processCodeBlock(ifStmt.body, closureIndex: &closureIndex)
        
        // Recurse into the 'else' block if it's a code block
        let updatedElseBody = ifStmt.elseBody.map { elseBody -> IfExprSyntax.ElseBody in
            switch elseBody {
            case .codeBlock(let block):
                let newBlock = processCodeBlock(block, closureIndex: &closureIndex)
                return .codeBlock(newBlock)
            case .ifExpr(let nestedIf):
                // Might be another 'if' for else-if chain, or single statement
                let newIf = processIf(nestedIf, closureIndex: &closureIndex)
                return .ifExpr(newIf)
            }
        }
        
        return ifStmt
            .with(\.body, updatedBody)
            .with(\.elseBody, updatedElseBody)
    }
    
    private func processCodeBlock(_ block: CodeBlockSyntax, closureIndex: inout Int) -> CodeBlockSyntax {
        var newItems = CodeBlockItemListSyntax { }
        for statement in block.statements {
            newItems.append(contentsOf: dfsInsertProfiling(statement, closureIndex: &closureIndex))
        }
        return block.with(\.statements, newItems)
    }
    
    private func processGuard(_ guardStmt: GuardStmtSyntax, closureIndex: inout Int) -> GuardStmtSyntax {
        let updatedBody = processCodeBlock(guardStmt.body, closureIndex: &closureIndex)
        return guardStmt.with(\.body, updatedBody)
    }
    
    private func processForIn(_ forStmt: ForStmtSyntax, closureIndex: inout Int) -> ForStmtSyntax {
        let updatedBody = processCodeBlock(forStmt.body, closureIndex: &closureIndex)
        return forStmt.with(\.body, updatedBody)
    }
    
    private func processWhile(_ whileStmt: WhileStmtSyntax, closureIndex: inout Int) -> WhileStmtSyntax {
        let updatedBody = processCodeBlock(whileStmt.body, closureIndex: &closureIndex)
        return whileStmt.with(\.body, updatedBody)
    }
    
    private func processRepeatWhile(_ repeatStmt: RepeatStmtSyntax, closureIndex: inout Int) -> RepeatStmtSyntax {
        let updatedBody = processCodeBlock(repeatStmt.body, closureIndex: &closureIndex)
        return repeatStmt.with(\.body, updatedBody)
    }
}
