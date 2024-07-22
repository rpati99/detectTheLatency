//
//  File1.swift
//  detectlatency
//
//  Created by Rachit Prajapati on 6/22/24.
//

import Foundation
import SwiftUI

struct ContentView: View {
    
    @State private var isToggled: Bool = false
    @State private var sliderValue: Float = 0.0
    @State private var name: String = ""
    @State private var asyncResult: String = "No data"
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    
                    //SwiftUI element that contains a function
                    Button {
                        execute()
                    } label: {
                        Text("label")
                    }
                    
                    //SwiftUI element that contains a function that is enclosed inside a loop
                    Text("Tap me")
                        .onTapGesture {
                            for i in 1...5 {
                                print("Loop iteration \(i)")
                                loopNestedFunction(i)
                            }
                            tapAction()
                        }
                    
                    //SwiftUI element that contains another SwiftUI element that contains a method
                    //and a looping code that contains another method (nested detection case)
                    Text("Long press me")
                        .contextMenu {
                            Button(action: {
                                for i in 1...5 {
                                    print("Loop iteration \(i)")
                                    loopNestedFunction(i)
                                }
                                contextAction()
                                
                            }) {
                                Text("Perform action")
                            }
                        }
                    
                    //SwiftUI element that contains 2 methods
                    Toggle(isOn: $isToggled) {
                        Text("Toggle me")
                    }
                    .onChange(of: isToggled) { newValue in
                        toggleValueChanged(newValue)
                        checkToggleCondition(newValue)
                    }
                    
                    //SwiftUI element that contains the looping mechanism to initiate calling that contains 2 methods
                    Slider(value: $sliderValue, in: 0...100, step: 1)
                        .onChange(of: sliderValue) { newValue in
                            sliderValueChanged(newValue)
                            adjustSliderBasedOnValue(newValue)
                        }
                    
                    //SwiftUI element that contains a method
                    Text("Drag me")
                        .onDrag {
                            performDragAction()
                            return NSItemProvider(object: "DragData" as NSString)
                        }
                    
                    // SwiftUI view that presents the status of async result (for viewing purpose  on an iOS application)
                    Text(asyncResult)
                        .padding()
                    
                    //SwiftUI element that contains asynchronous executable and
                    //an execution code inside it as an anonymous function (closure)
                    Button("Fetch Data") {
                        Task {
                            await fetchData({
                                print("Completion called")
                            })
                        }
                    }
                }
            }
        }
    }
    
    func execute() {
        print("execute called")
        nestedFunctionCallExample()
    }
    
    func tapAction() {
        print("tapAction called")
    }
    
    func contextAction() {
        print("contextAction called")
    }
    
    func toggleValueChanged(_ newValue: Bool) {
        print("Toggle value \(newValue)")
    }
    
    func checkToggleCondition(_ newValue: Bool) {
        if newValue {
            print("Toggle is ON")
        } else {
            print("Toggle is OFF")
        }
    }
    
    func sliderValueChanged(_ newValue: Float) {
        print("Slider value \(newValue)")
    }
    
    func adjustSliderBasedOnValue(_ newValue: Float) {
        if newValue > 50 {
            print("Slider value is greater than 50")
        } else {
            print("Slider value is 50 or less")
        }
    }
    
    func performDragAction() {
        print("drag action performed")
    }
    



    func loopNestedFunction(_ iteration: Int) {
        print("Nested function in loop, iteration \(iteration)")
    }
    
    func nestedFunctionCallExample() {
        print("Nested function call example started")
        firstLevelFunction()
    }
    
    func firstLevelFunction() {
        print("First level function")
        secondLevelFunction()
    }
    
    func secondLevelFunction() {
        print("Second level function")
        thirdLevelFunction()
    }
    
    func thirdLevelFunction() {
        print("Third level function")
    }
    
    func fetchData(_ completion:  () -> Void) async {
        print("Fetching data...")
        let url = URL(string: "https://jsonplaceholder.typicode.com/todos/1")!
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let title = json["title"] as? String {
                asyncResult = title
                print("Data fetched: \(title)")
                completion()
            } else {
                asyncResult = "Failed to parse data"
                print("Failed to parse data")
            }
        } catch {
            asyncResult = "Fetch error: \(error)"
            print("Fetch error: \(error)")
        }
    }
}

struct QuoteView: View {
    
    @Binding var name: String
    
    var body: some View {
        ZStack {
            Text("This is a Quote View with \(name)")
        }
    }
}
