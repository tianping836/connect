// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CaseNetwork",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        /// 双平台 App —— iOS (iPhone + iPad) + macOS 原生
        /// 通过 `xcodebuild -scheme CaseNetwork -destination 'platform=iOS' archive`
        /// 或 `xcodebuild -scheme CaseNetwork -destination 'platform=macOS' archive` 归档
        .executable(
            name: "CaseNetwork",
            targets: ["CaseNetwork"]
        ),
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "CaseNetwork",
            path: "CaseNetwork",
            // App/ 目录含 @main 入口，全部源文件参与编译
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "CaseNetworkTests",
            dependencies: ["CaseNetwork"],
            path: "Tests/CaseNetworkTests"
        ),
    ]
)
