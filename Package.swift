// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Latency Graph for ClashX Meta",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "Latency Graph for ClashX Meta", targets: ["LatencyGraphForClashXMeta"])
    ],
    targets: [
        .executableTarget(
            name: "LatencyGraphForClashXMeta",
            path: "Sources/LatencyGraphForClashXMeta",
            linkerSettings: [
                .linkedLibrary("sqlite3")
            ]
        )
    ]
)
