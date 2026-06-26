# Changelog

このプロジェクトの主な変更点を記録します。
書式は [Keep a Changelog](https://keepachangelog.com/ja/1.1.0/) に準拠し、
[Semantic Versioning](https://semver.org/lang/ja/) を採用します。

## [Unreleased]

## [0.1.0] - 2026-06-27

### Added
- 🧠 共通コアモジュール `SwiftGuardCore`
  - Apple **FoundationModels**（オンデバイスLLM / Private Cloud Compute）を用いた監査エンジン
  - 4 観点レビュー（循環参照・スレッド安全性・パフォーマンス・プライバシー規約）を日本語でストリーミング出力
  - `@Generable` による構造化リスク判定（SAFE / WARNING / CRITICAL）
  - `.swift` ファイルの再帰スキャナ（`.build` 等を自動除外）
  - モデル利用可否の判定とわかりやすい日本語メッセージ
- 💻 CLI ツール `swiftguard`（swift-argument-parser）
  - 単一ファイル / ディレクトリ対応、ANSI カラー・区切り線付きストリーミング出力
  - `--strict` / `--quiet` / `--no-color` / `--max-chars` オプション
- 🖼 SwiftUI デスクトップアプリ
  - ドラッグ&ドロップ、Markdown 表示、進捗バー
  - 依存ライブラリなしの軽量 Markdown レンダラ
- 🪝 Git `pre-commit` フックとインストーラ（重大な問題でコミットをブロック）
- 📀 配布ビルドスクリプト `build.sh`（ユニバーサル `.app` / `.dmg` を生成）
- 🎨 アプリアイコン生成器（AppKit で描画 → `.icns`）
- 📝 日英バイリンガル README、MIT ライセンス、CI ワークフロー

[Unreleased]: https://github.com/your-org/SwiftGuard/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/your-org/SwiftGuard/releases/tag/v0.1.0
