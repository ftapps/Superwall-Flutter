// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "superwallkit_flutter",
    platforms: [
        .iOS("14.0"),
    ],
    products: [
        .library(name: "superwallkit-flutter", targets: ["superwallkit_flutter"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
        // Kept in lockstep with the `SuperwallKit` pin in superwallkit_flutter.podspec.
        .package(url: "https://github.com/superwall/Superwall-iOS.git", exact: "4.16.1"),
    ],
    targets: [
        .target(
            name: "superwallkit_flutter",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                .product(name: "SuperwallKit", package: "Superwall-iOS"),
            ]
        )
    ]
)
