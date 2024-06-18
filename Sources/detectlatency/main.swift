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
let inputSwiftUISnippet = """
import SwiftUI
var ContentView: some View {
NavigationView {
    ZStack {
        VStack {

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

             NavigationLink(destination: DetailView()) {
                    Text("Go to Details")
                }
            }
        }
    }
}
"""


class InteractiveElementVisitor: SyntaxVisitor {
    
    var isInsideInteractiveElement = false
    var closureProcessed = false

    let interactiveKeywords: Set<String> = ["Button", "onTapGesture", "contextMenu", "onChange", "onDrag", "Slider", "NavigationLink"]
    
    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        processFunctionCall(node)
        return .visitChildren
    }
    
    func processFunctionCall(_ node: FunctionCallExprSyntax) {
        if let calledExpression = node.calledExpression.as(DeclReferenceExprSyntax.self) {
            let container = interactiveKeywords.contains(calledExpression.baseName.text)
            if container {
            isInsideInteractiveElement = true
                processFunctionCallSemantics(node, forComponent: calledExpression.baseName.text)
//                for argument in node.arguments {
//                    if let closure = argument.expression.as(ClosureExprSyntax.self) {
////                      print("Closure in \(calledExpression.baseName.text): \(closure.description)")
//                        //to handle function declaration style closures
//                        //sub closure detected
////                        processClosureExprSyntax(closure)
//                    } else {
////                    print("Function call in \(calledExpression.baseName.text): \(argument.description)")
//                        //doesn't detect syntax properly
//                    }
//                }
            }
        }
    }
    
    private func processFunctionCallSemantics(_ node: FunctionCallExprSyntax, forComponent component: String) {
        
        var closureFound = false
        
        for (index, argument) in node.arguments.enumerated() {
            if let closure = argument.expression.as(ClosureExprSyntax.self) {
                if component == "NavigationLink" && index == 0 {
                    print("NavigationLink closure \n \(closure.description)")
                    closureFound = true
                } else if component == "Button" && argument.label?.text == "action" {
                    print("Button with action found \n \(closure.description)")
                    closureFound = true
                } else if component == "Slider" || component == "Toggle" && argument.label?.text == "onChange" {
                    print("\(component) found \n \(closure.description)")
                    closureFound = true
                }
                if closureFound {
                    closureProcessed = true
                    break
                }
            }
        }
        
    }
    
    
    override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
//        nodeStack.append(Syntax(node))
//        TODO:- PREPROCESS THE CLOSURE and then iterate over it
        if isInsideInteractiveElement {
            
            if closureProcessed {
                closureProcessed = false
                return .visitChildren
            }
        
                for statement in node.statements {
                    //Checking if there is another tappable ui element delcared in it
                    if statement.description.contains("Button") ||
                        statement.description.contains("onTapGesture") ||
                        statement.description.contains("contextMenu") ||
                        statement.description.contains("onChange") ||
                        statement.description.contains("onDrag") ||
                        statement.description.contains("Slider") {
                        continue
                        //Converting statement to a closure and fetching the code/function
                        //NOTE:- full nested closures detected hlet codeBlockItem: CodeBlockItemSyntax = ... // Assume this comes from some parsing logic
                        //                            let closureNode = ClosureExprSyntax(statements: CodeBlockItemListSyntax([statement]))
                        //                        for subStatement in closureNode.statements {
                        //                            print("Sub statement code")
                        //                            print(subStatement)
                        //                        }
                    } else {
                        print("Code retrieved is \(statement)")
                    }
                }
        }
        return .visitChildren
    }
    
    func processClosureExprSyntax(_ node: ClosureExprSyntax) {
        for statement in node.statements {
            print("processed closure method extracted \(statement)")
        }
    }
//   // Iterates over the contents inside function
//    override func visitPost(_ node: FunctionCallExprSyntax) {
////        print("Post node looks like this \n, \(node)")
////        isInsideInteractiveElement = false
////        _ = nodeStack.popLast()  // Pop the current node as we are leaving it
////        if isInsideInteractiveElement {
////            isInsideInteractiveElement = false  // Reset the flag when leaving an interactive element
////        }
//    }
}

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


let sourceFile = Parser.parse(source: inputSwiftUISnippet)
let visitor = InteractiveElementVisitor(viewMode: .all)
visitor.walk(sourceFile)

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
