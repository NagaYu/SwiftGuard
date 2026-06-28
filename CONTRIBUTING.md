# Contributing to SwiftGuard

Contributions are very welcome! / コントリビュートを歓迎します！

## 🇺🇸 Getting started

1. **Open an issue first** — for bug reports and feature proposals.
2. **Fork & branch** — branch off `main` (e.g. `feature/xxx` or `fix/xxx`).
3. **Build & test** — make sure the following pass before opening a PR:

```bash
swift build
swift test
# If only the Command Line Tools are active, point at the Xcode toolchain:
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift build
```

4. **Install the pre-commit hook (recommended)** — `./scripts/install-hooks.sh`

### Good areas to contribute

- 🔍 **Audit dimensions (prompts)** — `Sources/SwiftGuardCore/AuditCategory.swift`
  (append one entry to `AuditCategory.all` and it flows into the CLI, GUI, and hook)
- 🌐 **Localization** — switching the review output language
- 🎨 **GUI / output formatting** improvements
- 🧪 **Tests** — `Tests/SwiftGuardCoreTests/`

### Coding guidelines

- Match the style (naming, comment density) of the surrounding code.
- Document public APIs.
- Keep shared logic in `SwiftGuardCore` so the CLI and GUI both reuse it.

By contributing, you agree that your contributions are licensed under the
project's [MIT License](LICENSE).

## 🇯🇵 はじめに（日本語）

まず Issue を立て、`main` からブランチを切り、`swift build` と `swift test` が通ることを
確認してから PR を送ってください（Command Line Tools のみの環境では
`DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` を付与）。
共通ロジックは `SwiftGuardCore` に置いてください。観点（プロンプト）の追加・改善、
出力フォーマットの改善、多言語対応などのアイデアを歓迎します。ありがとうございます！🙏
