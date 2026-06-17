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
            resources: nil
        ),
        .testTarget(
            name: "CaseNetworkTests",
            dependencies: ["CaseNetwork"],
            path: "Tests/CaseNetworkTests"
        ),
    ]
)
