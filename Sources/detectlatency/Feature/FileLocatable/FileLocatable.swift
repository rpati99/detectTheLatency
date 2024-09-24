//
//  SwiftFileLocatable.swift
//  detectlatency
//
//  Created by Rachit Prajapati on 9/19/24.
//

import Foundation

public protocol FileLocatable {
    func findSwiftFiles(directory: String) -> [URL]
}
