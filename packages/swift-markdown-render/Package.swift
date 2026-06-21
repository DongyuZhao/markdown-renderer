// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "swift-markdown-render",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "swift-markdown-render",
            targets: ["SwiftMarkdownRender"]
        )
    ],
    targets: [
        .target(
            name: "SwiftMarkdownRender"
        )
    ]
)
