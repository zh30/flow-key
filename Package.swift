// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FlowKey",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "FlowKey",
            targets: ["FlowKey"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/ml-explore/mlx-swift.git", from: "0.17.0"),
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from: "4.3.0"),
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.9.0"),
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture.git", from: "1.9.0")
    ],
    targets: [
        .executableTarget(
            name: "FlowKey",
            dependencies: [
                .product(name: "MLX", package: "mlx-swift"),
                .product(name: "SwiftyJSON", package: "SwiftyJSON"),
                .product(name: "Alamofire", package: "Alamofire")
            ],
            path: "Sources/FlowKey",
            exclude: ["Resources/Models"],
            resources: [
                .process("Resources"),
                .copy("Resources/Models")
            ]
        ),
        .target(
            name: "FlowKeyInputMethod",
            dependencies: [
                "FlowKey"
            ],
            path: "Sources/FlowKeyInputMethod"
        ),
        .testTarget(
            name: "FlowKeyTests",
            dependencies: ["FlowKey"],
            path: "Sources/FlowKeyTests"
        )
    ]
)