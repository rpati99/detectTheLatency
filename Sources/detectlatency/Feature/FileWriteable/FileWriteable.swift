//
//  File.swift
//  detectlatency
//
//  Created by Rachit Prajapati on 9/19/24.
//

import Foundation
import SwiftSyntax

public protocol FileWriteable {
    func writeModifiedCodeToSourceFile(_ modifiedContent: SourceFileSyntax, to url: URL)
}
