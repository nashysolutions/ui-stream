// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "ui-stream",
    platforms: [.iOS(.v17)],
    products: [
        .library(
            name: "UIStream",
            targets: ["UIStream"]
        ),
    ],
    targets: [
        .target(
            name: "UIStream"
        )
    ]
)
