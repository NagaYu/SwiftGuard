// swift-tools-version: 6.0
// SwiftGuard — 完全ローカルの Swift コード安全監査ツール
// Apple FoundationModels（オンデバイスLLM / Private Cloud Compute）を利用。

import PackageDescription

let package = Package(
    name: "SwiftGuard",
    // FoundationModels は macOS 26 (Tahoe) 以降が必要。
    platforms: [
        .macOS("26.0")
    ],
    products: [
        // CLI / GUI 双方から再利用する共通コアモジュール。
        .library(
            name: "SwiftGuardCore",
            targets: ["SwiftGuardCore"]
        ),
        // コマンドラインツール本体。
        .executable(
            name: "swiftguard",
            targets: ["swiftguard"]
        ),
        // SwiftUI デスクトップアプリ本体（.app へパッケージングして配布）。
        .executable(
            name: "SwiftGuardApp",
            targets: ["SwiftGuardApp"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-argument-parser.git",
            from: "1.3.0"
        ),
    ],
    targets: [
        // MARK: - 共通コア（AIロジック + ファイルスキャン）
        .target(
            name: "SwiftGuardCore"
        ),

        // MARK: - CLI
        .executableTarget(
            name: "swiftguard",
            dependencies: [
                "SwiftGuardCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),

        // MARK: - GUI (SwiftUI)
        .executableTarget(
            name: "SwiftGuardApp",
            dependencies: ["SwiftGuardCore"]
        ),

        // MARK: - テスト
        .testTarget(
            name: "SwiftGuardCoreTests",
            dependencies: ["SwiftGuardCore"]
        ),
    ]
)
