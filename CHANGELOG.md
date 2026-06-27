# Changelog

このプロジェクトの主な変更点を記録します。
書式は [Keep a Changelog](https://keepachangelog.com/ja/1.1.0/) に準拠し、
[Semantic Versioning](https://semver.org/lang/ja/) を採用します。

## [Unreleased]

### Added
- 監査観点を構造化した `AuditCategory`。各観点に専門的なチェックリストを付与し、
  システム指示（プロンプト）を観点定義から自動生成するように変更（観点の追加が容易に）。
- 監査観点を 2 つ追加: 💥 **強制アンラップ / クラッシュ耐性**、🧯 **エラーハンドリング**（計 6 観点）。
- 重大度の判定基準・出力フォーマット・誤検出（ハルシネーション）抑制ルールをプロンプトに明文化。
- CLI に `--rules` オプションを追加（監査する観点とチェックリストをモデル不要で表示）。
- デスクトップアプリに監査結果の **コピー** / **Markdown 保存** ボタンを追加。

### Changed
- `swiftguard` の `path` 引数を任意化し、`--rules` 単体で実行できるように。
- 1 ファイルあたりの既定の最大監査文字数を 12000 → 8000 に変更（オンデバイスモデルの
  コンテキスト超過を防ぐため）。

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

[Unreleased]: https://github.com/NagaYu/SwiftGuard/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/NagaYu/SwiftGuard/releases/tag/v0.1.0
