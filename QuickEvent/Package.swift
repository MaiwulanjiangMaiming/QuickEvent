// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "QuickEvent",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "QuickEvent",
            targets: ["QuickEvent"]
        )
    ],
    targets: [
        .executableTarget(
            name: "QuickEvent",
            path: "QuickEvent"
        )
    ]
)
