// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "better_social_share",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "better-social-share", targets: ["better_social_share"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "better_social_share",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            linkerSettings: [
                .linkedFramework("MessageUI"),
                .linkedFramework("Photos"),
            ]
        )
    ]
)
