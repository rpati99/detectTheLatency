//
//  MethodProfilingInserter.swift
//  callgraphbuilder
//
//  Created by Rachit Prajapati on 1/22/25.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftParser


class MethodProfilingInserter: SyntaxRewriter {
    let message: String // carries the name of existing function for specific output
    // Global set to track which functions have already been modified.
    nonisolated(unsafe) static var modifiedFunctions: Set<String> = []

    init(message: String) {
        self.message = message
        super.init()
    }

    override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
        
        guard let body = node.body else { return super.visit(node) }
        var closureIndex = 0
        let functionName = node.name.text

        // If already modified, skip processing.
        if MethodProfilingInserter.modifiedFunctions.contains(functionName) {
            return DeclSyntax(node)
        }

        // Prepare a timing code block to be inserted at the top of the function body.
        let parentProfiler = """
        
            var asyncTime: Double = 0
            asyncTime += 0
            var syncTime: Double = 0
            let syncStartTime = DispatchTime.now()
            defer {
                let syncEndTime = DispatchTime.now()
                syncTime = Double(syncEndTime.uptimeNanoseconds - syncStartTime.uptimeNanoseconds) / 1_000_000_000
                recordExecutionTime(functionName: "\(functionName)", syncTime: syncTime, asyncTime: asyncTime)
            }
        
        """
        
        let timingCodeStatements = Parser.parse(source: parentProfiler).statements

        // Recursively process each statement in the function body using DFS.
        var modifiedStatements = CodeBlockItemListSyntax { }
        // Insert the timing code first.
        modifiedStatements.append(contentsOf: timingCodeStatements)
        for stmt in body.statements {
            modifiedStatements.append(contentsOf: dfsInsertProfiling(stmt, closureIndex: &closureIndex, functionName: functionName))
        }

        // Create the new function body.
        let newBody = body.with(\.statements, modifiedStatements)
        MethodProfilingInserter.modifiedFunctions.insert(functionName)
        return super.visit(node.with(\.body, newBody))
            .as(DeclSyntax.self) ?? DeclSyntax(node)
    }

    /// DFS traversal that processes nested scopes for Task, escaping closures, and also
    /// recurses into conditionals and loops.
    private func dfsInsertProfiling(_ statement: CodeBlockItemSyntax, closureIndex: inout Int, functionName: String) -> [CodeBlockItemSyntax] {
        var modifiedStatements: [CodeBlockItemSyntax] = []

        // --- Handle Task block ---
        if let taskCall = statement.item.as(FunctionCallExprSyntax.self),
           let taskName = taskCall.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text,
           taskName == "Task" {
            if let taskClosure = taskCall.trailingClosure {
                let updatedTaskClosure = insertProfilingIntoTaskClosure(taskClosure, closureIndex: &closureIndex, functionName: functionName)
                let updatedTaskCall = ExprSyntax(taskCall.with(\.trailingClosure, updatedTaskClosure))
                let updatedStatement = statement.with(\.item, .expr(updatedTaskCall))
                modifiedStatements.append(updatedStatement)
                return modifiedStatements
            }
        }

        // --- Handle Task.detached block ---
        if let functionCall = statement.item.as(FunctionCallExprSyntax.self),
           let detached = functionCall.calledExpression.as(MemberAccessExprSyntax.self),
           detached.declName.baseName.text == "detached" {
            if let taskClosure = functionCall.trailingClosure {
                let updatedTaskClosure = insertProfilingIntoTaskClosure(taskClosure, closureIndex: &closureIndex, functionName: functionName)
                let updatedTaskCall = ExprSyntax(functionCall.with(\.trailingClosure, updatedTaskClosure))
                let updatedStatement = statement.with(\.item, .expr(updatedTaskCall))
                modifiedStatements.append(updatedStatement)
                return modifiedStatements
            }
        }

        // --- Handle escaping closures ---
        if let functionCall = statement.item.as(FunctionCallExprSyntax.self),
           hasEscapingClosure(functionCall) {
            let updatedBlock = insertProfilingIntoEscapingClosures(functionCall, closureIndex: &closureIndex, functionName: functionName)
            let updatedStatements = updatedBlock.statements.map { $0 }
            modifiedStatements.append(contentsOf: updatedStatements)
            return modifiedStatements
        }

        // --- Recurse into conditionals and loops ---
        if let ifStmt = statement.item.as(IfExprSyntax.self) {
            let updatedIf = processIf(ifStmt, closureIndex: &closureIndex, functionName: functionName)
            let updatedStatement = statement.with(\.item, .expr(ExprSyntax(updatedIf)))
            modifiedStatements.append(updatedStatement)
            return modifiedStatements
        }
        if let forStmt = statement.item.as(ForStmtSyntax.self) {
            let updatedFor = processForIn(forStmt, closureIndex: &closureIndex, functionName: functionName)
            let updatedStatement = statement.with(\.item, .stmt(StmtSyntax(updatedFor)))
            modifiedStatements.append(updatedStatement)
            return modifiedStatements
        }
        if let whileStmt = statement.item.as(WhileStmtSyntax.self) {
            let updatedWhile = processWhile(whileStmt, closureIndex: &closureIndex, functionName: functionName)
            let updatedStatement = statement.with(\.item, .stmt(StmtSyntax(updatedWhile)))
            modifiedStatements.append(updatedStatement)
            return modifiedStatements
        }
        if let repeatStmt = statement.item.as(RepeatStmtSyntax.self) {
            let updatedRepeat = processRepeatWhile(repeatStmt, closureIndex: &closureIndex, functionName: functionName)
            let updatedStatement = statement.with(\.item, .stmt(StmtSyntax(updatedRepeat)))
            modifiedStatements.append(updatedStatement)
            return modifiedStatements
        }
        
        // No special handling; return the statement as-is.
        modifiedStatements.append(statement)
        return modifiedStatements
    }

    /// Check if a function call has an escaping closure (via labeled or trailing closure)
    public func hasEscapingClosure(_ functionCall: FunctionCallExprSyntax) -> Bool {
        let hasLabeled = functionCall.arguments.contains { argument in
            argument.expression.as(ClosureExprSyntax.self) != nil
        }
        let hasTrailing = functionCall.trailingClosure != nil
        return hasLabeled || hasTrailing
    }

    // MARK: - Insertion Helpers

    public func insertProfilingIntoTaskClosure(_ closure: ClosureExprSyntax, closureIndex: inout Int, functionName: String) -> ClosureExprSyntax {
        let profilingCode = """
        
            let asyncStartTime = DispatchTime.now()
            defer {
                let asyncEndTime = DispatchTime.now()
                let asyncTimeElapsed = Double(asyncEndTime.uptimeNanoseconds - asyncStartTime.uptimeNanoseconds) / 1_000_000_000
                
                 
                Task { @MainActor in 
                    asyncTime += asyncTimeElapsed
                recordExecutionTime(functionName: "\(functionName)", syncTime: syncTime, asyncTime: asyncTime)
                }
            }
        
        """
        let profilingStmts = Parser.parse(source: profilingCode).statements
        var updatedStmts = profilingStmts
        for stmt in closure.statements {
            updatedStmts.append(contentsOf: dfsInsertProfiling(stmt, closureIndex: &closureIndex, functionName: functionName))
        }
        return closure.with(\.statements, updatedStmts)
    }

    public func insertProfilingIntoEscapingClosures(_ functionCall: FunctionCallExprSyntax, closureIndex: inout Int, functionName: String) -> CodeBlockSyntax {
        // Use a simple startTime variable name and increment manually if needed.
        let startTimeVarName = "asyncStartTime\(closureIndex)"
        closureIndex += 1
        
        let startTimeCode = """
           
               let \(startTimeVarName) = DispatchTime.now()
           """
        
        let startTimeStmts = Parser.parse(source: startTimeCode).statements
        
        let updatedArguments = functionCall.arguments.map { argument -> LabeledExprSyntax in
            if let closure = argument.expression.as(ClosureExprSyntax.self) {
                let updatedClosure = insertProfilingIntoEscapingClosure(closure, startTimeVarName: startTimeVarName, closureIndex: &closureIndex, functionName: functionName)
                return argument.with(\.expression, ExprSyntax(updatedClosure))
            }
            return argument
        }
        
        var updatedFunctionCall = functionCall.with(\.arguments, LabeledExprListSyntax(updatedArguments))
        if let trailingClosure = functionCall.trailingClosure {
            let updatedTrailingClosure = insertProfilingIntoEscapingClosure(trailingClosure, startTimeVarName: startTimeVarName, closureIndex: &closureIndex, functionName: functionName)
            updatedFunctionCall = updatedFunctionCall.with(\.trailingClosure, updatedTrailingClosure)
        }
        
        var updatedStmts = startTimeStmts
        updatedStmts.append(CodeBlockItemSyntax(item: .expr(ExprSyntax(updatedFunctionCall))))
        
        let finalBlock = CodeBlockSyntax {
            for stmt in updatedStmts {
                stmt
            }
        }
        return finalBlock
    }

    public func insertProfilingIntoEscapingClosure(_ closure: ClosureExprSyntax, startTimeVarName: String, closureIndex: inout Int, functionName: String) -> ClosureExprSyntax {
        let deferCode = """
        
            defer {
                let asyncEndTime = DispatchTime.now()
                let asyncTimeElapsed = Double(asyncEndTime.uptimeNanoseconds - \(String(describing: startTimeVarName)).uptimeNanoseconds) / 1_000_000_000
                asyncTime += asyncTimeElapsed
                recordExecutionTime(functionName: "\(functionName)", syncTime: syncTime, asyncTime: asyncTime)
            }
        
        """
        let deferStmts = Parser.parse(source: deferCode).statements
        var updatedStmts = deferStmts
        for stmt in closure.statements {
            updatedStmts.append(contentsOf: dfsInsertProfiling(stmt, closureIndex: &closureIndex, functionName: functionName))
        }
        return closure.with(\.statements, updatedStmts)
    }

    // MARK: - Conditionals & Loops Processing

    private func processIf(_ ifNode: IfExprSyntax, closureIndex: inout Int, functionName: String) -> IfExprSyntax {
        let updatedBody = processCodeBlock(ifNode.body, closureIndex: &closureIndex, functionName: functionName)
        let updatedElse = ifNode.elseBody.map { elseBody -> IfExprSyntax.ElseBody in
            switch elseBody {
            case .codeBlock(let block):
                let newBlock = processCodeBlock(block, closureIndex: &closureIndex, functionName: functionName)
                return .codeBlock(newBlock)
            case .ifExpr(let nestedIf):
                let newIf = processIf(nestedIf, closureIndex: &closureIndex, functionName: functionName)
                return .ifExpr(newIf)
            }
        }
        return ifNode.with(\.body, updatedBody).with(\.elseBody, updatedElse)
    }

    // runs when the traversal detects the conditional statements and loop statements to perform insertions under async components
    private func processCodeBlock(_ block: CodeBlockSyntax, closureIndex: inout Int, functionName: String) -> CodeBlockSyntax {
        var newItems = CodeBlockItemListSyntax { }
        for stmt in block.statements {
            newItems.append(contentsOf: dfsInsertProfiling(stmt, closureIndex: &closureIndex, functionName: functionName))
        }
        return block.with(\.statements, newItems)
    }

    private func processWhile(_ whileNode: WhileStmtSyntax, closureIndex: inout Int, functionName: String) -> WhileStmtSyntax {
        let updatedBody = processCodeBlock(whileNode.body, closureIndex: &closureIndex, functionName: functionName)
        return whileNode.with(\.body, updatedBody)
    }

    private func processForIn(_ forNode: ForStmtSyntax, closureIndex: inout Int, functionName: String) -> ForStmtSyntax {
        let updatedBody = processCodeBlock(forNode.body, closureIndex: &closureIndex, functionName: functionName)
        return forNode.with(\.body, updatedBody)
    }

    private func processRepeatWhile(_ repeatNode: RepeatStmtSyntax, closureIndex: inout Int, functionName: String) -> RepeatStmtSyntax {
        let updatedBody = processCodeBlock(repeatNode.body, closureIndex: &closureIndex, functionName: functionName)
        return repeatNode.with(\.body, updatedBody)
    }
}

