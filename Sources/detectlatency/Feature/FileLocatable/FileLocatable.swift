//
//  SwiftFileLocatable.swift
//  detectlatency
//
//  Created by Rachit Prajapati on 9/19/24.
//

import Foundation

// Interface to handle location of Swift files 
public protocol FileLocatable {
    func findSwiftFiles(directory: String) -> [URL]
}
