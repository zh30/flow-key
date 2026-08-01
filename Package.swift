// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "FlowKey",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .executable(
            name: "FlowKey",
            targets: ["FlowKey"]
        ),
        .executable(
            name: "FlowKeyInputMethod",
            targets: ["FlowKeyInputMethod"]
        ),
    ],
    targets: [
        .executableTarget(
            name: "FlowKey",
            path: "Sources/FlowKey/Rebuilt",
            resources: [
                .process("Resources"),
            ]
        ),
        .target(
            name: "FlowKeyInputMethodCore",
            path: "Sources/FlowKeyInputMethodCore"
        ),
        .executableTarget(
            name: "FlowKeyInputMethod",
            dependencies: ["FlowKeyInputMethodCore"],
            path: "Sources/FlowKeyInputMethod/Rebuilt",
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "FlowKeyTests",
            dependencies: ["FlowKey", "FlowKeyInputMethodCore"],
            path: "Sources/FlowKeyTests"
        ),
    ],
    swiftLanguageModes: [.v5]
)
