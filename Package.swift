// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "ReteEngine",
    products: [
        .library(
            name: "ReteEngine",
            targets: ["ReteEngine"]),
    ],
    targets: [
        .target(
            name: "ReteEngine",
            dependencies: []),
        .testTarget(
            name: "ReteEngineTests",
            dependencies: ["ReteEngine"]),
    ]
)
