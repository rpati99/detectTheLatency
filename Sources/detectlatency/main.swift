/*
 
main.swift for declaring code at top level. 
 
 */

import SwiftParser // For parsing the input code
import SwiftSyntax // For incorporating filtering logic for code detection
import Foundation // Using Swift APIs
import SwiftSyntaxBuilder // Generate code 


//// Declaring the parser
//private func processParsingWith(file: String) {
//    let fileContents: String
//    let fileURL = URL(filePath: "/Users/rp/detectlatency/File1.swift")
//    
//    do {
//        fileContents = try String.init(contentsOf: fileURL, encoding: .utf8)
//        //  debugPrint(fileContents.trimmingCharacters(in: .whitespacesAndNewlines))
//        let processedFileContent = fileContents.trimmingCharacters(in: .whitespacesAndNewlines)
//        
//        // Declaring parser
//        let parsedContent = Parser.parse(source: processedFileContent)
//        
//        // Declaring modifier that visits the parsed syntax tree with the logic
//        let visitorViewModifier = CodeExtractorService(viewMode: .all)
//        
//        // Initating the code extraction
//        visitorViewModifier.walk(parsedContent)
//        
//    } catch let error {
//        print("Error processing file contents \(error.localizedDescription)")
//    }
//}
//
//// Fetching the user defined code
//processParsingWith(file: "/Users/rp/detectlatency/File1.swift")

//CallerService.parseCode()







