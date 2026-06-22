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
    dependencies: [
        .package(url: "https://github.com/DongyuZhao/cmark-gfm", branch: "main")
    ],
    targets: [
        .target(
            name: "SwiftMarkdownRender",
            dependencies: [
                .product(name: "cmark-gfm", package: "cmark-gfm")
            ]
        )
    ]
)
