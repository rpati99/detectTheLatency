import SwiftParser // For parsing the input code
import SwiftSyntax // For incorporating filtering logic for code detection
import SwiftUI
import Foundation

//Use cases of the user driven interactions

//let inputSwiftUISnippet = Parser.parse(source: <#T##String#>)

// Declaring the parser

private func processParsingWith(file: String) {
    let fileContents: String
    let fileURL = URL(filePath: "/Users/rp/detectlatency/File1.swift")
    
    do {
        fileContents = try String.init(contentsOf: fileURL, encoding: .utf8)
//        debugPrint(fileContents.trimmingCharacters(in: .whitespacesAndNewlines))
        let processedFileContent = fileContents.trimmingCharacters(in: .whitespacesAndNewlines)
        let parsedContent = Parser.parse(source: processedFileContent)
        let visitorViewModifier = ViewModifierClosureExtractor(viewMode: .all)
        visitorViewModifier.walk(parsedContent)
        
    } catch let error {
        print("Error processing file contents \(error.localizedDescription)")
    }
//    let parser = Parser.parse(source: )
    // Declaring the scanning logic that initiates the parsing of the source tree.
//    let visitorViewModifier = ViewModifierClosureExtractor(viewMode: .all)
//
//    // Iterating over the parsed code/ Abstract Syntax tree
//    visitorViewModifier.walk(fileContents)
}

processParsingWith(file: "/Users/rp/detectlatency/File1.swift")




// Service that iterates over the source tree and contains logic that provides the code snippet that will be running upon user interaction
class ViewModifierClosureExtractor: SyntaxVisitor {
    // Set that contains keywords that will only process closures required, TODO:- change to view and build another one that is ViewModifier
    let interactiveViewsList: Set<String> = ["Button", "contextMenu", "Slider", "NavigationLink"]
    let interactiveViewModifiersList: Set<String> = ["onTapGesture", "onChange", "onDrag"]
    
    var isInsideInteractiveElement = false
    
    // Handle view closures
    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        processFunctionCall(node)
        return .visitChildren
    }
    
    // Handle view closures
    private func processFunctionCall(_ node: FunctionCallExprSyntax) {
        
        // Handle Views
        if let calledExpression = node.calledExpression.as(DeclReferenceExprSyntax.self) {
            let contains = interactiveViewsList.contains(calledExpression.baseName.text)
           
            if contains {
                isInsideInteractiveElement = true
                processFunctionCallSemantics(node, forComponent: calledExpression.baseName.text)
            }
        }
        
        // Handle View Modifiers
        // Fetching the expression in order to differentiate the closure desired from the rest
        if let memberAccess = node.calledExpression.as(MemberAccessExprSyntax.self) {
            
            // Condition that checks if it fits in the desired bracket and only processes when affirmative
            if interactiveViewModifiersList.contains(memberAccess.declName.baseName.text) { // MemberAccessExprsyntax -> trailing closure syntax
                let modifierName = memberAccess.declName.baseName.text
//                print("Detected view modifier: \(modifierName)")
                
                // Check if there's a trailing closure directly associated with the view modifier
                if let trailingClosure = node.trailingClosure {
                    print("Closure for \(modifierName): \(trailingClosure.statements.description)")
                }
                
                // Check if the closure is part of the argument list
                for argument in node.arguments {
                    if let closure = argument.expression.as(ClosureExprSyntax.self) {
                        print("Closure for \(modifierName): \(closure.statements.description)")
                    }
                }
            }
        }
    }
    
    private func processFunctionCallSemantics(_ node: FunctionCallExprSyntax, forComponent component: String) {
        
//        print("node \(node) with component is \(component)")
        
        var closureFound = false

        
        if let trailingClosure = node.trailingClosure, component == "Button" {
            if node.arguments.allSatisfy({ $0.label == nil }) {
                        print("Button action closure found (trailing): \(trailingClosure.description)")
                    }
        }
        
        for (index, argument) in node.arguments.enumerated() {
            if let closure = argument.expression.as(ClosureExprSyntax.self) {
               
                if component == "NavigationLink" && index == 0 {
                    print("Navigation link closure code detected \(closure.description)")
                    closureFound = true
                } else if component == "Button" && argument.label?.text == "action" {
                    print("Button with action code found \(closure.description)")
                    closureFound = true
                } else if component == "Button"  && (node.trailingClosure?.statements.count) ?? 0 > 0 {
                    print("Button with closure found \(String(describing: closure.description))")
                    closureFound = true
                }
            }
            
            if closureFound {
                break
            }
        }
    }
    

    
    // iterating over the source tree with a type that process function syntax

    
    // TODO:- Add functionCallExprSyntax logic and dissect the the interacrtive keywords from Views to View Modifiers
}



// Below code contains the logic that processes the SwiftUI views
//class InteractiveElementVisitor: SyntaxVisitor {
//    
//    var isInsideInteractiveElement = false
////    var closureProcessed = false
////    var relevantClosure = false
////    var discaredClosures: Set<ClosureExprSyntax> = []
//
//    let interactiveKeywords: Set<String> = ["Button", ".onTapGesture", "contextMenu", "onChange", "onDrag", "Slider", "NavigationLink"]
//    
//    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
//        processFunctionCall(node)
//        return .visitChildren
//    }
//    
//    func processFunctionCall(_ node: FunctionCallExprSyntax) {
//        if let calledExpression = node.calledExpression.as(MemberAccessExprSyntax.self) {
////            let container = interactiveKeywords.contains(calledExpression.baseName.text)
////            print("Called expression is \(calledExpression)")
////            processFunctionCallSemantics(node, forComponent: calledExpression.baseName.text)
//            print("called expression is \(calledExpression)")
////            if container {
//            isInsideInteractiveElement = true
//               
//                for argument in node.arguments {
//                    if let closure = argument.expression.as(ClosureExprSyntax.self) {
//                      print("Closure in \(calledExpression): \(closure.description)")
//                        //to handle function declaration style closures
//                        //sub closure detected
////                        processClosureExprSyntax(closure)
//              
//                    } else {
////                    print("Function call in \(calledExpression.baseName.text): \(argument.description)")
//                        //doesn't detect syntax properly
//                    }
////                }
//            }
//        }
//    }
//    
//    // Logic that focuses on the scanning of relevant SwiftUI views that contain user driven spaces.
//    private func processFunctionCallSemantics(_ node: FunctionCallExprSyntax, forComponent component: String) {
//        
//        print("node \(node) with component is \(component)")
//        
//        var closureFound = false
//        for (index, argument) in node.arguments.enumerated() {
//            print(index, argument)
//            
////            if let closure = argument.expression.as(ClosureExprSyntax.self) {
////                
////                print("Argument is \(argument) and index is \(index)")
////                if component == "NavigationLink" && index == 0 {
////                    print("NavigationLink closure \n \(closure.description)")
////                    closureFound = true
////                } else if component == "Button" && argument.label?.text == "action" {
////                    print("Button with action found \n \(closure.description)")
////                    closureFound = true
////                } else if component == "Button" && argument.label == nil && index == 1 {
////                    print("Processing Button label closure: \(closure.description)")
////                        closureFound = true
////                    // component == "Slider" || component == "Toggle" &&
////                } else if  argument.label?.text == "onChange" {
////                    print("\(component) found \n \(closure.description)")
////                    closureFound = true
////                } else if component == "onTapGesture" {
////                    print("Processing onTapGesture closure: \(closure.description)")
////                    closureFound = true
////                } else if component == "onDrag" {
////                    print("Processing onDrag closure: \(closure.description)")
////                                    closureFound = true
////                }
////                if closureFound {
////                    break
////                }
////            }
//        }
//        
//    }
//    
//     
////    override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
//////        nodeStack.append(Syntax(node))
//////        TODO:- PREPROCESS THE CLOSURE and then iterate over it
////        if isInsideInteractiveElement {
////            
//////            if closureProcessed || discaredClosures.contains(node) {
//////                closureProcessed = false
//////                return .visitChildren
//////            }
////        
////                for statement in node.statements {
////                    //Checking if there is another tappable ui element delcared in it
////                    if statement.description.contains("Button") ||
////                        statement.description.contains("onTapGesture") ||
////                        statement.description.contains("contextMenu") ||
////                        statement.description.contains("onChange") ||
////                        statement.description.contains("onDrag") ||
////                        statement.description.contains("Slider") {
////                        continue
////                        //Converting statement to a closure and fetching the code/function
////                        //NOTE:- full nested closures detected hlet codeBlockItem: CodeBlockItemSyntax = ... // Assume this comes from some parsing logic
////                        //                            let closureNode = ClosureExprSyntax(statements: CodeBlockItemListSyntax([statement]))
////                        //                        for subStatement in closureNode.statements {
////                        //                            print("Sub statement code")
////                        //                            print(subStatement)
////                        //                        }
////                    } else {
////                        print("Code retrieved is \(statement)")
////                    }
////                }
////        }
////        return .visitChildren
////    }
//    
////    func processClosureExprSyntax(_ node: ClosureExprSyntax) {
////        for statement in node.statements {
////            print("processed closure method extracted \(statement)")
////        }
////    }
////   // Iterates over the contents inside function
////    override func visitPost(_ node: FunctionCallExprSyntax) {
//////        print("Post node looks like this \n, \(node)")
//////        isInsideInteractiveElement = false
//////        _ = nodeStack.popLast()  // Pop the current node as we are leaving it
//////        if isInsideInteractiveElement {
//////            isInsideInteractiveElement = false  // Reset the flag when leaving an interactive element
//////        }
////    }
//}

      // Iterates over high levels functions
//class FunctionDeclarationVisitor: SyntaxVisitor {
//    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
//        print("Sep Class Function declaration: \(node.name.text)")
//        print("Sep Class Function node : \(node)")
////        if let body = node.body {
////
////            print("Function body: \(body.description)")
//
////        }
//        return .visitChildren
//    }
//}

//
//
//let visitor = InteractiveElementVisitor(viewMode: .all)
//visitor.walk(sourceFile)

//let demoSwiftUICode = """
//                    Button(action: {
//                        contextAction()
//                    }) {
//                        Text("Perform action")
//                    }
//"""
//
//
//let demoParsedCode = Parser.parse(source: demoSwiftUICode)
//dump(demoParsedCode)
