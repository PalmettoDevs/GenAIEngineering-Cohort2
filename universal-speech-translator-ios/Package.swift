// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "UniversalTranslator",
    platforms: [.iOS(.v17)],
    targets: [
        .executableTarget(
            name: "UniversalTranslator",
            path: "UniversalTranslator"
        )
    ]
)
