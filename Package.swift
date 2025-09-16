// swift-tools-version: 6.0
// FlowKey Package.swift with macOS 26 support

import PackageDescription

let package = Package(
    name: "FlowKey",
    platforms: [
        .macOS(.v15)
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
            sources: [
                "App/SimpleFlowKeyApp.swift",
                "App/AppDelegate.swift",
                "Services/LocalizationService.swift",
                "Services/ModernLocalizationService.swift",
                "Services/ModernTranslationService.swift",
                "InputMethod/FlowInputController.swift",
                "InputMethod/ModernFlowInputController.swift",
                "Views/ModernContentView.swift",
                "Views/ModernSettingsView.swift"
            ], // 包含多语言服务和现代化组件
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