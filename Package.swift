// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DemoConsole",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(
            name: "DemoConsole",
            targets: ["DemoConsole"]
        ),
    ],
    targets: [
        .executableTarget(
            name: "DemoConsole",
            path: "DemoConsole"
        ),
    ]
)
