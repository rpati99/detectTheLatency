// swift-tools-version:5.10
import PackageDescription

let package = Package(
   
    name: "detectlatency",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        // Change this to define an executable, not a library.
        .executable(
            name: "detectlatency",
            targets: ["detectlatency"]
        ),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0"),
        .package(url: "https://github.com/apple/swift-collections.git",.upToNextMinor(from: "1.1.0")) // for callgraphbuilder module
    ],
    targets: [
        // Declare this as an executable target since 'main.swift' is present.
        .executableTarget(
            name: "detectlatency",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
                .product(name: "Collections", package: "swift-collections")
            ],
            path: "Sources"  // Path to the directory containing 'main.swift'
            
        ),
    ]
)
