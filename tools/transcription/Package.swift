// swift-tools-version: 6.2
import PackageDescription
let package = Package(
    name: "LocalTranscription",
    platforms: [.macOS(.v14)],
    dependencies: [.package(path: "../FluidAudio", traits: [])],
    targets: [
        .executableTarget(name: "Transcribe", dependencies: [.product(name: "FluidAudio", package: "FluidAudio")]),
        .testTarget(name: "TranscribeTests", dependencies: ["Transcribe"]),
    ]
)
