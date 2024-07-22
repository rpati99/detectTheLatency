# detectTheLatency

*Swift package that performs to measurement of the execution time of the code which is to be ran upon user interaction.* 


**This package utilizes following principles to perform the objective using SwiftSyntax.**

- Combination of Static and Dynamic analysis.

- Code Detection (SyntaxVisitor).

- Code Generation[[1]](https://www.github.com/rpati99/timingMacro) (SwiftSyntax + Macros)

- Code Insertion (SyntaxRewriter)


*[1] Macro that measures execution time of any input code.*
