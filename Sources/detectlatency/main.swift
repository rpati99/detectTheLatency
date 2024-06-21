import SwiftParser
import SwiftSyntax

//l """
//        NavigationLink(destination: {
//            QuoteView(name: $name).toolbar(.hidden)
//        }, label: {
//            Text("Continue")
//                .foregroundStyle(.white)
//                .padding()
//                .background(Capsule().fill(Color.black))
//                .shadow(radius: 10)
//            
//        })
//"""

//Use cases of the user driven interactions
"""
                        Button {
                            execute()
                        } label: {
                            Text("label")
                        }

            Text("Tap me")
                .onTapGesture {
                    tapAction()
                }

            Text("Long press me")
                .contextMenu {
                    Button(action: {
                        contextAction()
                    }) {
                        Text("Perform action")
                    }
                }

            Slider(value: $sliderValue, in: 0...100, step: 1)
                .onChange(of: sliderValue) { newValue in
                    sliderValueChanged(newValue)
                }

            Toggle(isOn: $isToggled) {
                Text("Toggle me")
            }
            .onChange(of: isToggled) { newValue in
                toggleValueChanged(newValue)
            }

            Text("Drag me")
                .onDrag {
                    performDragAction()
                    return NSItemProvider(object: "DragData" as NSString)
                }

          NavigationLink(destination: {
              QuoteView(name: $name).toolbar(.hidden)
          }, label: {
              Text("Continue")
                  .foregroundStyle(.white)
                  .padding()
                  .background(Capsule().fill(Color.black))
                  .shadow(radius: 10)
              
          })
"""
let inputSwiftUISnippet = """
import SwiftUI
var ContentView: some View {
NavigationView {
    ZStack {
        VStack {

            Text("Tap me")
                .onTapGesture {
                    tapAction()
                }

            Toggle(isOn: $isToggled) {
                Text("Toggle me")
            }
            .onChange(of: isToggled) { newValue in
                toggleValueChanged(newValue)
            }

            Slider(value: $sliderValue, in: 0...100, step: 1)
                .onChange(of: sliderValue) { newValue in
                    sliderValueChanged(newValue)
                }

            }
        }
    }
}
"""

// Declaring the parser
let sourceFile = Parser.parse(source: inputSwiftUISnippet)


// Service that iterates over the source tree and contains logic that provides the code snippet that will be running upon user interaction

class ViewModifierClosureExtractor: SyntaxVisitor {
    // Set that contains keywords that will only process closures required
    let interactiveKeywords: Set<String> = ["Button", "onTapGesture", "contextMenu", "onChange", "onDrag", "Slider", "NavigationLink"]
    
    // iterating over the source tree with a type that process function syntax
    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        
        // Fetching the expression in order to differentiate the closure desired from the rest
        if let memberAccess = node.calledExpression.as(MemberAccessExprSyntax.self) {
            
            // Condition that checks if it fits in the desired bracket and only processes when affirmative
            if interactiveKeywords.contains(memberAccess.declName.baseName.text) { // MemberAccessExprsyntax -> trailing closure syntax
                let modifierName = memberAccess.declName.baseName.text
                print("Detected view modifier: \(modifierName)")
                
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
        return .visitChildren
    }
    
    // TODO:- Add functionCallExprSyntax logic and dissect the the interacrtive keywords from Views to View Modifiers
}

// Declaring the scanning logic that initiates the parsing of the source tree.
let visitorViewModifier = ViewModifierClosureExtractor(viewMode: .all)

// Iterating over the parsed code/ Abstract Syntax tree
visitorViewModifier.walk(sourceFile)

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
