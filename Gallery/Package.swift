// swift-tools-version: 6.2
import Foundation
import PackageDescription

// A path dependency is named after its folder, whatever the clone is called.
let kit = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().lastPathComponent

// Renders the design kit's gallery offscreen. Not part of the ThemeKit package: `swift run --package-path Gallery
// DesignKitGallery <output directory>` on macOS.
let package = Package(
    name: "DesignKitGallery",
    platforms: [.macOS(.v26)],
    dependencies: [.package(path: "..")],
    targets: [
        .executableTarget(
            name: "DesignKitGallery",
            dependencies: [
                .product(name: "ColorCore", package: kit),
                .product(name: "ColorPlatform", package: kit),
                .product(name: "ColorUI", package: kit),
                .product(name: "DesignKit", package: kit),
            ]),
    ])
