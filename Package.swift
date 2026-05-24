// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "WebKitPrivateHeaders",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "WebKitPrivate", targets: ["WebKitPrivate"]),
        .library(name: "CWebKitPrivate", targets: ["CWebKitPrivate"]),
    ],
    targets: [
        .target(
            name: "CWebKitPrivate",
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("include"),
            ],
        ),
        .target(
            name: "WebKitPrivate",
            dependencies: ["CWebKitPrivate"],
            swiftSettings: [.swiftLanguageMode(.v6)],
        ),
        .testTarget(
            name: "WebKitPrivateTests",
            dependencies: ["WebKitPrivate", "CWebKitPrivate"],
            swiftSettings: [.swiftLanguageMode(.v6)],
        ),
    ],
)
