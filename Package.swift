// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "terminal-bundleid",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
    ],
    targets: [
        .target(
            name: "TerminalBundleID"
        ),
        .executableTarget(
            name: "terminal-bundleid",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "TerminalBundleID",
            ]
        ),
        .testTarget(
            name: "TerminalBundleIDTests",
            dependencies: ["TerminalBundleID"]
        ),
    ]
)
