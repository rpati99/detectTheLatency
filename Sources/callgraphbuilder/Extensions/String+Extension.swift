//
//  String+Extension.swift
//  callgraphbuilder
//
//  Created by Rachit Prajapati on 1/30/25.
//

import Foundation

extension String {
    /// Checks if a string matches any object type in a dictionary
    func matchesObjectType(_ objectTypes: [String: String]) -> Bool {
        return objectTypes.values.contains(self)
    }
}
