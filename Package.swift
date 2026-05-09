// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "proc-appinfo",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
    ],
    targets: [
        .target(
            name: "ProcAppInfo"
        ),
        .executableTarget(
            name: "proc-appinfo",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "ProcAppInfo",
            ]
        ),
        .testTarget(
            name: "ProcAppInfoTests",
            dependencies: ["ProcAppInfo"]
        ),
    ]
)
