// swift-tools-version: 5.9
// 简化版 FlowKey Package.swift 用于快速构建

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
        // 暂时注释掉复杂依赖项，先构建基础版本
        // .package(url: "https://github.com/ml-explore/mlx-swift.git", from: "0.17.0"),
        // .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from: "4.3.0"),
        // .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.9.0"),
        // .package(url: "https://github.com/pointfreeco/swift-composable-architecture.git", from: "1.9.0")
    ],
    targets: [
        .executableTarget(
            name: "FlowKey",
            dependencies: [
                // 暂时注释掉依赖项
                // .product(name: "MLX", package: "mlx-swift"),
                // .product(name: "SwiftyJSON", package: "SwiftyJSON"),
                // .product(name: "Alamofire", package: "Alamofire")
            ],
            path: "Sources/FlowKey",
            sources: ["App/SimpleFlowKeyApp.swift"], // 只使用简化版本
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "FlowKeyTests",
            dependencies: ["FlowKey"],
            path: "Sources/FlowKeyTests"
        )
    ]
)