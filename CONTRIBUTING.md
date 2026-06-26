# Contributing to SwiftGuard / コントリビュートガイド

SwiftGuard への貢献を歓迎します！ / Contributions are very welcome!

## 🇯🇵 はじめに

1. **Issue を立てる** — バグ報告・機能提案はまず Issue へ。
2. **フォーク & ブランチ** — `feature/xxx` や `fix/xxx` のブランチを切ってください。
3. **ビルド & テスト** — PR 前に必ず以下が通ることを確認してください。

```bash
swift build
swift test
# Command Line Tools のみの環境では Xcode ツールチェーンを指定:
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift build
```

4. **pre-commit フックの導入を推奨** — `./scripts/install-hooks.sh`

### 貢献しやすい領域

- 🔍 **監査観点（プロンプト）の改善** — `Sources/SwiftGuardCore/AuditPrompt.swift`
- 🌐 **多言語対応** — レビュー出力言語の切り替え
- 🎨 **GUI / 出力フォーマットの改善**
- 🧪 **テストの追加** — `Tests/SwiftGuardCoreTests/`

### コーディング規約

- 既存ファイルのスタイル（命名・コメント密度）に合わせてください。
- 公開 API には日本語のドキュメントコメントを付けてください。
- コアロジックは `SwiftGuardCore` に置き、CLI / GUI から共有してください。

## 🇺🇸 In short

Open an issue first, branch off `main`, make sure `swift build` and `swift test`
pass (use `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` if only the
Command Line Tools are active), then open a PR. Keep shared logic in
`SwiftGuardCore`. Thank you! 🙏

By contributing, you agree that your contributions are licensed under the
project's [MIT License](LICENSE).
