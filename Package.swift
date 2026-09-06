// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Rebootless",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Rebootless", targets: ["Rebootless"])
    ],
    targets: [
        .executableTarget(
            name: "Rebootless",
            path: "Sources/Rebootless"
        ),
        .testTarget(
            name: "RebootlessTests",
            dependencies: ["Rebootless"],
            path: "Tests/RebootlessTests"
        ),
    ]
)

