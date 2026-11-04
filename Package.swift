// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "ThemeKit",
    defaultLocalization: "en",
    platforms: [.macOS(.v26), .iOS(.v26)],
    products: [
        .library(name: "ColorCore", targets: ["ColorCore"]),
        .library(name: "ColorPlatform", targets: ["ColorPlatform"]),
        .library(name: "ColorUI", targets: ["ColorUI"]),
        .library(name: "DesignKit", targets: ["DesignKit"]),
    ],
    targets: [
        .target(name: "ColorCore"),
        .target(name: "ColorPlatform", dependencies: ["ColorCore"]),
        .target(
            name: "ColorUI", dependencies: ["ColorCore", "ColorPlatform"],
            resources: [.process("Resources")]),
        .testTarget(name: "ColorCoreTests", dependencies: ["ColorCore"]),
        .testTarget(name: "ColorPlatformTests", dependencies: ["ColorCore", "ColorPlatform"]),
        .testTarget(name: "ColorUITests", dependencies: ["ColorCore", "ColorPlatform", "ColorUI"]),
        .target(
            name: "DesignKit", dependencies: ["ColorCore", "ColorPlatform", "ColorUI"],
            resources: [.process("Resources")]),
        .testTarget(name: "DesignKitTests", dependencies: ["ColorCore", "ColorPlatform", "ColorUI", "DesignKit"]),
    ])
