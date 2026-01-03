// swift-tools-version:6.0

import PackageDescription

let package = Package(
    name: "swift-semi-secs",
    products: [
        .library(
            name: "SemiSecs",
            targets: ["SemiSecs"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "SemiSecs",
            dependencies: []),
        .testTarget(
            name: "SemiSecsTests",
            dependencies: ["SemiSecs"]),
    ]
)
