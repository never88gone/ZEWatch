// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "llama",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .watchOS(.v9)
    ],
    products: [
        .library(
            name: "llama",
            targets: ["llama"]
        ),
    ],
    targets: [
        .target(
            name: "llama",
            path: ".",
            sources: ["src"],
            publicHeadersPath: "include"
        )
    ],
    cxxLanguageStandard: .cxx17
)
