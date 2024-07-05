//
//  File1.swift
//  detectlatency
//
//  Created by Rachit Prajapati on 6/22/24.
//

import Foundation
import SwiftUI

struct ContentView: View {
    
    @State var isToggled: Bool = false
    @State var sliderValue: Float = 0.0
    @State var name: String = ""
    
    var body: some View {
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
                }
            }
        }
    }
    
    
    func execute() {
        print("execute called")
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
    
    func sliderValueChanged(_ newValue: Float) {
        print("Slider value \(newValue)")
    }
    
    func performDragAction() {
        print("drag action performed")
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
