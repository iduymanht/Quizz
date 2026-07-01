// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Quiz",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.6.0"),
    ],
    targets: [
        .target(
            name: "QuizCore",
            path: "Sources/QuizCore"
        ),
        .executableTarget(
            name: "Quiz",
            dependencies: ["QuizCore", .product(name: "Sparkle", package: "Sparkle")],
            path: "Sources/App",
            resources: [
                .copy("Resources/donate-vietqr.png"),
                .copy("Resources/en.lproj"),
                .copy("Resources/vi.lproj"),
                .copy("Resources/zh-Hans.lproj"),
                .copy("Resources/zh-Hant.lproj"),
            ]
        ),
        .testTarget(
            name: "QuizCoreTests",
            dependencies: ["QuizCore"],
            path: "Tests/QuizCoreTests"
        ),
        .testTarget(
            name: "QuizAppTests",
            dependencies: ["Quiz"],
            path: "Tests/QuizAppTests"
        ),
    ],
    // Build under the Swift 5 language mode (no Swift 6 strict-concurrency
    // checking) so the original app sources compile as they were written.
    swiftLanguageModes: [.v5]
)
