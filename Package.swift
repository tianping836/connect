// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CaseNetwork",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "CaseNetwork",
            targets: ["CaseNetwork"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "CaseNetwork",
            path: "CaseNetwork",
            exclude: ["App/CaseNetworkApp.swift"],  // iOS @main only works in Xcode project
            resources: nil
        ),
        .testTarget(
            name: "CaseNetworkTests",
            dependencies: ["CaseNetwork"],
            path: "Tests/CaseNetworkTests"
        ),
    ]
)
