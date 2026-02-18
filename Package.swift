// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "NetWarden",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "NetWarden", targets: ["NetWarden"])
    ],
    targets: [
        .executableTarget(
            name: "NetWarden"
        )
    ]
)
