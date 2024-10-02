//
//  AsyncInsertable.swift
//  detectlatency
//
//  Created by Rachit Prajapati on 10/1/24.
//

import Foundation
import SwiftSyntax

public protocol AsyncInsertable {
    func hasEscapingClosure(_ functionCall: FunctionCallExprSyntax) -> Bool
    func insertProfilingIntoTaskClosure(_ closure: ClosureExprSyntax) -> ClosureExprSyntax
    func insertProfilingIntoEscapingClosures(_ functionCall: FunctionCallExprSyntax, closureIndex: inout Int) -> CodeBlockSyntax
    func insertProfilingIntoEscapingClosure(_ closure: ClosureExprSyntax, startTimeVarName: String) -> ClosureExprSyntax

}
