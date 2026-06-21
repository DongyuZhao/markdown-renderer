// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "swift-markdown-render-sample",
    platforms: [
        .macOS(.v12)
    ],
    dependencies: [
        .package(path: "../../packages/swift-markdown-render")
    ],
    targets: [
        .executableTarget(
            name: "swift-markdown-render-sample",
            dependencies: [
                .product(name: "swift-markdown-render", package: "swift-markdown-render")
            ]
        )
    ]
)
