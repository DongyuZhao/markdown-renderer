// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "swiftui-markdown",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "swiftui-markdown",
            targets: ["SwiftUIMarkdown"]
        )
    ],
    targets: [
        .target(
            name: "SwiftUIMarkdown"
        )
    ]
)
