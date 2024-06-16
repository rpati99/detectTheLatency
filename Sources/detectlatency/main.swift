import SwiftParser
import SwiftSyntax
import SwiftUI

let inputSwiftUISnippet =
"""
import SwiftUI
var ContentView: some View {
    ZStack {
        VStack {
        Button {
            execute()
        } label: {
            Text("lol")
        }
}
    }

    func execute() {
        print("Tapped")
    }

    func execute2() {
        print("dummy func")
    }
}
"""

let inputSnippet =
"""
var sum = 1 + 2

func greeting(name: String) {
    print("Hello world!")
}
"""


// Parse the source code in sourceText   a syntax tree
let parsedCode: SourceFileSyntax = Parser.parse(source: inputSwiftUISnippet)


//syntax tree
//dump(parsedCode)

class ButtonActionVisitor: SyntaxVisitor {
    var foundButtonAction: Bool = false

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        if let calledExpression = node.calledExpression.as(DeclReferenceExprSyntax.self),
           calledExpression.baseName.text == "Button" {
            foundButtonAction = true
            return .visitChildren
        }
        return .visitChildren
    }

    override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
        if foundButtonAction {
            print(node.description)
            foundButtonAction = false // Reset for next potential Button
        }
        return .visitChildren
    }
}



let funcVisitor = ButtonActionVisitor(viewMode: .all)
funcVisitor.walk(parsedCode)


//dump(parsedCode)
