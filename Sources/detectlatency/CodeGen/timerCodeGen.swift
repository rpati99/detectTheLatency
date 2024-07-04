//
//  timerCodeGen.swift
//
//
//  Created by Rachit Prajapati on 7/3/24.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftParser


//let swiftUICode  = """
//    Button(action: {
//        print("Button tapped")
//    }, label: {
//        Text("Tap me")
//    })
//"""
//
//class CallerService {
//    static func parseCode() {
//        let parseCode = Parser.parse(source: swiftUICode)
//        dump(parseCode)
//    }
//}


let funcName = "printTwoWords"
let funcParameterNameOne = "wordOne"
let funcParameterNameTwo = "wordTwo"
let funcReturnType = "String"

let funcHeader = """
public func \(funcName) (\(funcParameterNameOne) : String, \(funcParameterNameTwo) : String) -> \(funcReturnType)
"""


//let funcBuilder = FunctionDeclSyntax(name: <#T##TokenSyntax#>, signature: <#T##FunctionSignatureSyntax#>, bodyBuilder: <#T##() throws -> CodeBlockItemListSyntax?#>)



