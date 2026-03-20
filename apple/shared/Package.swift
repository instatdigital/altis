// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "AltisAppleShared",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "AltisAppleShared",
            targets: ["AltisAppleShared"]
        )
    ],
    targets: [
        .target(
            name: "AltisAppleShared"
        ),
        .testTarget(
            name: "AltisAppleSharedTests",
            dependencies: ["AltisAppleShared"]
        )
    ]
)
