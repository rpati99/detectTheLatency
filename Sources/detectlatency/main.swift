import SwiftParser
import SwiftSyntax

let inputSwiftUISnippet =
"""
import SwiftUI
var ContentView: some View {
    ZStack {
        VStack {
            Button {
                execute()
            } label: {
                Text("Button")
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
        }
    }
}

"""


let sourceFile = Parser.parse(source: inputSwiftUISnippet)

class InteractiveElementVisitor: SyntaxVisitor {
    
    var isInsideInteractiveElement = false
    
    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        processFunctionCall(node)
        return .visitChildren
    }
    
    func processFunctionCall(_ node: FunctionCallExprSyntax) {
        if let calledExpression = node.calledExpression.as(DeclReferenceExprSyntax.self) {
            let container = ["Button", "onTapGesture", "contextMenu", "onChange", "onDrag", "Slider"].contains(calledExpression.baseName.text)
            if container {
            isInsideInteractiveElement = true
                for argument in node.arguments {
                    if let closure = argument.expression.as(ClosureExprSyntax.self) {
//                      print("Closure in \(calledExpression.baseName.text): \(closure.description)")
                        //to handle function declaration style closures
                        //sub closure detected
                        print("FROM FUNCTION CODE")
                        processClosureExprSyntax(closure)
                    } else {
//                    print("Function call in \(calledExpression.baseName.text): \(argument.description)")
                        //doesn't detect syntax properly
                    }
                }
            }
        }
    }
    
    
    override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
        if isInsideInteractiveElement {
                for statement in node.statements {
                    //Checking if there is another tappable ui element delcared in it
                    if statement.description.contains("Button") ||  statement.description.contains("onTapGesture") ||
                        statement.description.contains("contextMenu") ||
                        statement.description.contains("onChange") ||
                        statement.description.contains("onDrag") ||
                        statement.description.contains("Slider") {
                        
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
//                    if contains {
//                        print(statement)
//                    }
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
//    }
}

//      // Iterates over high levels functions 
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

let interactiveElementVisitor = InteractiveElementVisitor(viewMode: .all)
//let functionDeclarationVisitor = FunctionDeclarationVisitor(viewMode: .all)
interactiveElementVisitor.walk(sourceFile)

