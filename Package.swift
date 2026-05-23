// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ftpad",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "ftpad",
            dependencies: ["ftpadCore"],
            path: "Sources/App"
        ),
        .target(
            name: "ftpadCore",
            path: "Sources/Core"
        ),
        .testTarget(
            name: "ftpadTests",
            dependencies: ["ftpadCore"],
            path: "Tests"
        ),
    ]
)
