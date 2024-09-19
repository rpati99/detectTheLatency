//
//  SwiftFileLocatable.swift
//  detectlatency
//
//  Created by Rachit Prajapati on 9/19/24.
//

import Foundation

public protocol SwiftFileLocatable {
    func findSwiftFiles(directory: String) -> [URL]
}
