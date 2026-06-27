<div align="center">

# 🛡 SwiftGuard

**完全ローカルで動く、Swift コード安全監査ツール**
**A fully on-device security & quality auditor for Swift code**

Powered by Apple's on-device LLM — [FoundationModels](https://developer.apple.com/documentation/foundationmodels)

[![Platform](https://img.shields.io/badge/platform-macOS%2026%2B-blue.svg)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-6.0%2B-orange.svg)](https://swift.org)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Privacy](https://img.shields.io/badge/privacy-100%25%20on--device-brightgreen.svg)](#-プライバシー--privacy)

[日本語](#-概要) ・ [English](#-overview)

</div>

---

## 🇯🇵 概要

**SwiftGuard** は、あなたの Swift コードを **一切外部に送信せず**、Mac 上の Apple オンデバイス LLM だけで監査するセキュリティ／品質チェックツールです。

「iOS / macOS のシニアエンジニア兼セキュリティ監査の専門家」としての視点で、以下の観点を **日本語** でレビューし、結果をストリーミング表示します（観点一覧は `swiftguard --rules` でも確認できます）。

| 観点 | 検出する内容の例 |
|------|------------------|
| 🔁 **循環参照 / メモリリーク** | クロージャの `self` 強参照、`delegate` の `weak` 漏れ、`Timer` / `Task` の retain cycle |
| 🧵 **スレッド安全性 / 並行性** | データ競合、`@MainActor` 違反、UI のメインスレッド外更新、非 `Sendable` 越境 |
| ⚡️ **パフォーマンス** | 不要なコピー、メインスレッドのブロッキング I/O、O(n²) ループ、過剰なオブジェクト生成 |
| 🔐 **プライバシー規約違反** | 許可なしの位置情報／連絡先／写真アクセス、機微情報のログ出力・平文保存・外部送信 |
| 💥 **強制アンラップ / クラッシュ耐性** | `!` の強制アンラップ、`try!` / `as!`、配列の範囲外アクセス、`fatalError` の本番発火 |
| 🧯 **エラーハンドリング** | `try?` での握りつぶし、空の `catch {}`、エラーの黙殺・未伝播 |

**CLI（コマンドライン）** と **デスクトップアプリ（SwiftUI）** の両方を提供します。

### ✨ 特長

- **完全ローカル / プライバシー保護** — コードは Mac の外に出ません（後述）。
- **2 つのインターフェース** — ターミナル派にも GUI 派にも。
- **Git pre-commit フック** — 危険なコードのコミットを自動でブロック。
- **共通コアモジュール** — AI ロジックは `SwiftGuardCore` に集約され、CLI / GUI で共有。
- **オープンソース (MIT)** — 個人・商用問わず無料。

---

## 🔐 プライバシー / Privacy

SwiftGuard は Apple の **FoundationModels** フレームワークを使用し、推論はすべて **オンデバイス** で実行されます。

- ソースコードは **インターネットに送信されません**。OpenAI 等の外部 API も一切使いません。
- 端末で処理しきれない場合でも、Apple の **Private Cloud Compute (PCC)** により、Apple ですら内容を読めない暗号化された状態で処理されます（Apple のサーバーにデータは保持されません）。
- ネットワークを切断した状態でも、対応モデルがあれば動作します。

> つまり、**社外秘・公開前のコードでも安心して監査できます。**

---

## 📦 動作要件 / Requirements

- **macOS 26 (Tahoe) 以降**
- **Apple Intelligence に対応した Mac**（Apple シリコン）で、**Apple Intelligence が有効**
  （ `設定 > Apple Intelligence & Siri` から有効化）
- ビルドには **Xcode 26 以降**（FoundationModels のマクロを使用するため）

---

## 🚀 インストール / Installation

### A. Homebrew（おすすめ・最も簡単）

証明書なしでも警告なくインストールできます。

```bash
# CLI（Gatekeeper 警告なしで導入されます）
brew install NagaYu/tap/swiftguard

# デスクトップアプリ
brew install --cask --no-quarantine NagaYu/tap/swiftguard
```

詳細: [NagaYu/homebrew-tap](https://github.com/NagaYu/homebrew-tap)

### B. デスクトップアプリ（DMG を手動）

1. [Releases](https://github.com/NagaYu/SwiftGuard/releases) から `SwiftGuard-x.y.z.dmg` をダウンロード
2. DMG を開き、`SwiftGuard.app` を `Applications` へドラッグ
3. 初回は `SwiftGuard.app` を**右クリック →「開く」**（未署名アプリのため）
4. フォルダ／ファイルをドラッグ＆ドロップ

> 自分でビルドする場合は [配布ビルド](#-配布ビルド--building-for-distribution) を参照。

### C. CLI（ソースからビルド）

```bash
git clone https://github.com/NagaYu/SwiftGuard.git
cd SwiftGuard

# リリースビルド
swift build -c release

# 任意: PATH に通す
cp .build/release/swiftguard /usr/local/bin/
```

---

## 🖥 使い方 / Usage

### CLI

```bash
# 単一ファイルを監査
swiftguard path/to/File.swift

# ディレクトリを再帰的に監査
swiftguard ./Sources

# 判定だけを高速表示（レビュー本文を省略）
swiftguard --quiet ./Sources

# CI / フック用: 重大な問題があれば終了コード 1
swiftguard --strict ./Sources

# 監査する観点とチェックリストを表示（モデル不要）
swiftguard --rules

# 結果を Markdown ファイルに保存（パイプ時はカラーなしのプレーン出力）
swiftguard ./Sources > report.md

# オンデバイスモデルの利用可否だけ確認（CI / フックの事前判定用）
swiftguard --check
```

| オプション | 説明 |
|-----------|------|
| `--rules` | 監査する観点とチェックリストを表示して終了（モデル不要） |
| `--check` | オンデバイスモデルの利用可否のみ確認して終了（利用可=`0` / 不可=`2`） |
| `--quiet` | Markdown レビューを省き、リスク判定バッジのみ表示（高速） |
| `--strict` | 🔴 CRITICAL が 1 件でもあれば exit code `1` |
| `--no-color` | カラー出力を無効化 |
| `--max-chars <n>` | 1 ファイルあたりの最大監査文字数（既定 8000） |

**終了コード:** `0` = 重大な問題なし / `1` = 重大な問題あり (`--strict`) / `2` = モデル利用不可・パスエラー・対象ファイルなし

### デスクトップアプリ

- **左ペイン**: `.swift` ファイルやフォルダをドラッグ＆ドロップ（またはボタンで選択）
- **右ペイン**: 監査結果が Markdown で見やすくストリーミング表示。**コピー** / **Markdown を保存** ボタン付き
- **下部**: ステータスと進捗バー

---

## 🪝 Git pre-commit フック

危険なコードのコミットを自動でブロックできます。

```bash
# リポジトリ直下で実行（.git/hooks/pre-commit を設置）
./scripts/install-hooks.sh
```

以後 `git commit` のたびに、ステージされた `.swift` が監査され、
🔴 CRITICAL が見つかるとコミットが中止されます。

```bash
SWIFTGUARD_SKIP=1 git commit ...   # 一時的に無効化
git commit --no-verify             # 1 回だけ回避
```

> **挙動メモ**: オンデバイスモデルを利用できない環境では、フックはコミットを止めません（fail-open）。
> また、ブロック判定（構造化リスク評価）は温度 0 で生成し、重大な問題が 1 件でもあれば安全側に
> 倒して 🔴 CRITICAL とみなすため、同じコードに対して安定した結果になります。

---

## 📀 配布ビルド / Building for Distribution

`.app` と `.dmg` をコマンド一発で生成します。

```bash
./scripts/build.sh         # CLI + .app + .dmg をまとめてビルド
./scripts/build.sh app     # .app のみ
./scripts/build.sh dmg     # .app + .dmg
./scripts/build.sh cli     # CLI のみ
```

成果物は `dist/` に出力されます（ユニバーサルバイナリ: arm64 + x86_64）。

### 署名・公証（任意 / 一般配布向け）

何も設定しなければ **ad-hoc 署名**でビルドされます（手元での利用やテストはこれで十分）。
Gatekeeper の警告なく広く配布したい場合は、Apple Developer ID で**署名・公証**できます。

```bash
# Developer ID で署名（hardened runtime 付き）
SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
  ./scripts/build.sh dmg

# 署名 + 公証 (notarization) + ステープルまで一括
# 事前に notarytool の認証情報を保存しておく:
#   xcrun notarytool store-credentials swiftguard-notary \
#     --apple-id "you@example.com" --team-id TEAMID --password <app専用パスワード>
SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
NOTARY_PROFILE="swiftguard-notary" \
  ./scripts/build.sh dmg
```

| 環境変数 | 説明 |
|---------|------|
| `SIGN_IDENTITY` | Developer ID 署名の Identity（未設定なら ad-hoc 署名） |
| `NOTARY_PROFILE` | `notarytool` に保存済みのプロファイル名（設定時のみ公証＆ステープル） |

---

## 🏗 アーキテクチャ / Architecture

AI ロジックとファイルスキャンは共通モジュール **`SwiftGuardCore`** に隔離され、CLI と GUI の両方から再利用されます。

```
SwiftGuard/
├── Package.swift
├── Sources/
│   ├── SwiftGuardCore/        # 🧠 共通コア（CLI / GUI 共有）
│   │   ├── AuditEngine.swift      # FoundationModels 呼び出し・ストリーミング
│   │   ├── AuditCategory.swift    # 監査観点の定義（チェックリスト）
│   │   ├── AuditPrompt.swift      # 観点からシステム指示を自動生成
│   │   ├── RiskAssessment.swift   # @Generable による構造化リスク判定
│   │   └── FileScanner.swift      # .swift ファイルの再帰収集
│   ├── swiftguard/            # 💻 CLI（swift-argument-parser）
│   │   ├── SwiftGuardCommand.swift
│   │   └── Terminal.swift         # ANSI カラー / 区切り線
│   └── SwiftGuardApp/         # 🖼 SwiftUI デスクトップアプリ
│       ├── SwiftGuardApp.swift
│       ├── ContentView.swift
│       ├── AuditViewModel.swift
│       └── MarkdownView.swift
├── Tests/SwiftGuardCoreTests/
└── scripts/                   # pre-commit / install-hooks.sh / build.sh
```

```
                 ┌───────────────────────────┐
   CLI  ───────▶ │      SwiftGuardCore        │ ──▶ FoundationModels
   GUI  ───────▶ │  AuditEngine / FileScanner │     (On-device LLM / PCC)
                 └───────────────────────────┘
```

> **観点の拡張は簡単**: `Sources/SwiftGuardCore/AuditCategory.swift` の `AuditCategory.all` に
> 1 要素を追加するだけで、CLI・GUI・pre-commit のプロンプトすべてに自動反映されます。

---

## 🧪 開発 / Development

```bash
swift build        # ビルド
swift test         # ユニットテスト
swift run swiftguard ./Examples   # サンプルを監査

# Command Line Tools のみがアクティブな環境では Xcode のツールチェーンを指定:
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift build
```

---

## 🤝 コントリビュート / Contributing

Issue / PR を歓迎します。観点（プロンプト）の追加・改善、出力フォーマットの改善、多言語対応などのアイデアをお待ちしています。

---

## 🇺🇸 Overview

**SwiftGuard** audits your Swift code for safety and quality **entirely on-device**, using Apple's FoundationModels LLM. **Your source code never leaves your Mac** — no external APIs, no telemetry.

Acting as a *"senior iOS/macOS engineer & security auditor"*, it reviews these dimensions and streams the results (run `swiftguard --rules` to list them):

- 🔁 **Retain cycles / memory leaks**
- 🧵 **Thread-safety & concurrency** (data races, `@MainActor` violations, off-main UI updates)
- ⚡️ **Performance waste** (blocking I/O, O(n²) loops, needless copies)
- 🔐 **Apple privacy-policy risks** (unauthorized location/contacts/photo access, leaking sensitive data)
- 💥 **Crash resilience** (force unwraps `!`, `try!` / `as!`, out-of-range access)
- 🧯 **Error handling** (swallowed errors, empty `catch {}`, ignored failures)

It ships as both a **CLI** and a **SwiftUI desktop app**, plus a **Git pre-commit hook** that blocks commits containing critical issues. The AI logic lives in a shared `SwiftGuardCore` module reused by both front-ends.

> **Note:** review output is in Japanese by default. To change the language, edit `AuditPrompt.systemInstructions` in `Sources/SwiftGuardCore/AuditPrompt.swift`.

### Quick start

```bash
# Easiest — via Homebrew (no certificate, no Gatekeeper warning):
brew install NagaYu/tap/swiftguard
swiftguard ./Sources

# Or from source:
git clone https://github.com/NagaYu/SwiftGuard.git
cd SwiftGuard
swift build -c release
swift run swiftguard ./Sources        # audit a directory
./scripts/build.sh dmg                # build SwiftGuard.app + .dmg
```

**Requirements:** macOS 26+, an Apple-Intelligence-capable Mac with Apple Intelligence enabled, Xcode 26+ to build.

---

## 📄 License

[MIT](LICENSE) © 2026 SwiftGuard Contributors — 個人・商用問わず無料で利用できます。
