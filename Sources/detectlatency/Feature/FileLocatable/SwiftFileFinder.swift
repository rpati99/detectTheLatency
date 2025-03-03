//
//  SwiftFileFinder.swift
//  detectlatency
//
//  Created by Rachit Prajapati on 9/19/24.
//

import Foundation

// Service that finds all Swift files inside the codebase. 
public struct SwiftFileFinder: FileLocatable {
    
    public func findSwiftFiles(directory: String) -> [URL] {
        let fileManager = FileManager.default
        var swiftFiles: [URL] = [] // Storing Swift files
        
        if let enumerator = fileManager.enumerator(atPath: directory) {
            for case let file as String in enumerator {
                if file.hasSuffix(".swift") {
                    let fullPath = URL(filePath: directory).appendingPathComponent(file)
                    swiftFiles.append(fullPath)
                }
            }
        }
        
        return swiftFiles
    }
}
