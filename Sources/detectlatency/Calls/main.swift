import SwiftParser // For parsing the input code
import SwiftSyntax // For incorporating filtering logic for code detection
import Foundation // Using Swift APIs
import SwiftSyntaxBuilder // Generate code 

// Declaring the parser
private func processParsingWith(file: String) -> SourceFileSyntax? {
    let fileContents: String
    let fileURL = URL(filePath: file)
    
    do {
        fileContents = try String.init(contentsOf: fileURL, encoding: .utf8)
        //  debugPrint(fileContents.trimmingCharacters(in: .whitespacesAndNewlines))
        let processedFileContent = fileContents.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Declaring parser
        let parsedContent = Parser.parse(source: processedFileContent)
        
        return parsedContent
        

        
    } catch let error {
        print("Error processing file contents \(error.localizedDescription)")
    }
    return nil
}

private func applyCodeExtractorService(parsedContent: SourceFileSyntax) {
    // Declaring modifier that visits the parsed syntax tree with the logic
    let visitorViewModifier = CodeExtractorService(viewMode: .all)
    
    // Initating the code extraction
    visitorViewModifier.walk(parsedContent)
}

// Fetching the user defined code

if let parsedCode = processParsingWith(file: "/Users/rp/detectlatency/Sources/detectlatency/TestFile.swift") {
    applyCodeExtractorService(parsedContent: parsedCode)
}
//processParsingWith(file: "/Users/rp/detectlatency/Sources/detectlatency/TestFile.swift")

let sourceCode  = """
    {
        print("1 + 2 = 3")
        var c = 4
        debugPrint("Hi")
    }
"""

let parseDemoCode = Parser.parse(source: sourceCode)
let codeRewriter = TimingCodeInserter()
let newCode = codeRewriter.visit(parseDemoCode)
print(newCode)

//
//
//
//// Service that iterates over the source tree and contains logic that provides the code snippet that will be running upon user interaction
//class ViewModifierClosureExtractor: SyntaxVisitor {
//    // Set that contains keywords that will only process closures required, TODO:- change to view and build another one that is ViewModifier
//    let interactiveViewsList: Set<String> = ["Button", "contextMenu", "Slider", "NavigationLink" ]
//    let interactiveViewModifiersList: Set<String> = ["onTapGesture", "onChange", "onDrag", "onDelete", "destructive", ]
//    
//    var isInsideInteractiveElement = false
//    
//    // Handle view closures
//    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
//        processFunctionCall(node)
//        return .visitChildren
//    }
//    
//    // Handle view closures
//    private func processFunctionCall(_ node: FunctionCallExprSyntax) {
//        
//        // Handle Views
//        if let calledExpression = node.calledExpression.as(DeclReferenceExprSyntax.self) {
//            let contains = interactiveViewsList.contains(calledExpression.baseName.text)
//            
//            if contains {
//                isInsideInteractiveElement = true
//                processFunctionCallSemantics(node, forComponent: calledExpression.baseName.text)
//            }
//        }
//        
//        // Handle View Modifiers
//        // Fetching the expression in order to differentiate the closure desired from the rest
//        if let memberAccess = node.calledExpression.as(MemberAccessExprSyntax.self) {
//            
//            // Condition that checks if it fits in the desired bracket and only processes when affirmative
//            if interactiveViewModifiersList.contains(memberAccess.declName.baseName.text) { // MemberAccessExprsyntax -> trailing closure syntax
//                let modifierName = memberAccess.declName.baseName.text
//                // print("Detected view modifier: \(modifierName)")
//                
//                // Check if there's a trailing closure directly associated with the view modifier
//                if let trailingClosure = node.trailingClosure {
//                    print("Closure for \(modifierName): \(trailingClosure.statements.description)")
//                }
//                
//                // Check if the closure is part of the argument list
//                for argument in node.arguments {
//                    if let closure = argument.expression.as(ClosureExprSyntax.self) {
//                        print("Closure for \(modifierName): \(closure.statements.description)")
//                    }
//                }
//            }
//        }
//    }
//    
//    private func processFunctionCallSemantics(_ node: FunctionCallExprSyntax, forComponent component: String) {
//        
//        var closureFound = false
//        
//        if let trailingClosure = node.trailingClosure {
//            if component == "Button" {
//                
//                // Check if there's at least one unlabeled closure or explicitly labeled as action
//                let handleRoleParameter = node.arguments.contains(where: { $0.label?.text == "role" })
//                let handleTitleParameter = node.arguments.contains(where: { $0.label?.text == "title" })
//                let hasUnlabeledArguments = node.arguments.allSatisfy({ $0.label == nil })
//                if hasUnlabeledArguments || handleTitleParameter || handleRoleParameter {
//                    print("Button with trailing closure found ): \(trailingClosure.description)")
//                }
//                closureFound = true
//            }
//        }
//        
//        
//        for (index, argument) in node.arguments.enumerated() {
//            if component == "NavigationLink" && index == 0 {
//                if let closure = argument.toClosure {
//                    print("Navigation link closure code detected \(closure.description)")
//                }
//                
//                closureFound = true
//            } else if component == "Button" {
//                if let _ = argument.label?.text.contains("action") {
//                    if let closure = argument.toClosure {
//                        print("Button with action code found \(closure.description)")
//                    }
//                    
//                    closureFound = true
//                } else if (node.trailingClosure?.statements.count) ?? 0 > 0 {
//                    if let closure = argument.toClosure {
//                        print("Button with closure found \(closure.description)")
//                    }
//                    closureFound = true
//                }
//            }
//            
//            if closureFound {
//                break
//            }
//        }
//    }
//    
//    
//}
//
//
//extension LabeledExprSyntax {
//    
//    var toClosure: ClosureExprSyntax? {
//        return self.expression.as(ClosureExprSyntax.self)
//    }
//    
//}



