<div align="center">

# 🛡 SwiftGuard

**A fully on-device security & quality auditor for Swift code**

Powered by Apple's on-device LLM — [FoundationModels](https://developer.apple.com/documentation/foundationmodels)

[![Platform](https://img.shields.io/badge/platform-macOS%2026%2B-blue.svg)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-6.0%2B-orange.svg)](https://swift.org)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Privacy](https://img.shields.io/badge/privacy-100%25%20on--device-brightgreen.svg)](#-privacy)

**English** ・ [日本語](README.ja.md)

</div>

---

## 📖 Overview

**SwiftGuard** audits your Swift code for safety and quality **entirely on-device**, using Apple's FoundationModels LLM. **Your source code never leaves your Mac** — no external APIs, no telemetry.

Acting as a *"senior iOS/macOS engineer & security auditor"*, it reviews the following dimensions and streams the results (run `swiftguard --rules` to list them):

| Dimension | Examples of what it catches |
|-----------|------------------------------|
| 🔁 **Retain cycles / memory leaks** | Strong `self` capture in closures, missing `weak` delegates, `Timer` / `Task` retain cycles |
| 🧵 **Thread-safety & concurrency** | Data races, `@MainActor` violations, off-main UI updates, non-`Sendable` crossings |
| ⚡️ **Performance** | Needless copies, blocking I/O on the main thread, O(n²) loops, excessive allocations |
| 🔐 **Apple privacy-policy risks** | Unauthorized location/contacts/photo access, logging or storing sensitive data in plaintext |
| 💥 **Crash resilience** | Force unwraps `!`, `try!` / `as!`, out-of-range access, `fatalError` in production paths |
| 🧯 **Error handling** | Swallowed errors via `try?`, empty `catch {}`, ignored / un-propagated failures |

It ships as both a **CLI** and a **SwiftUI desktop app**, plus a **Git pre-commit hook** that blocks commits containing critical issues.

### ✨ Highlights

- **100% local / privacy-preserving** — your code never leaves the Mac (see below).
- **Two interfaces** — a terminal CLI and a native desktop app.
- **Git pre-commit hook** — automatically blocks commits with dangerous code.
- **Shared core module** — the AI logic lives in `SwiftGuardCore`, reused by both front-ends.
- **Open source (MIT)** — free for personal and commercial use.

> **Note:** review output is in Japanese by default. To change the language, edit `AuditPrompt.systemInstructions` in `Sources/SwiftGuardCore/AuditPrompt.swift`.

---

## 🔐 Privacy

SwiftGuard uses Apple's **FoundationModels** framework and runs all inference **on-device**.

- Your source code is **never sent over the internet** — no OpenAI or other external APIs.
- When a request can't be handled locally, Apple's **Private Cloud Compute (PCC)** processes it in an encrypted form that not even Apple can read, and no data is retained on Apple's servers.
- It works even with networking disabled, as long as a supported model is available.

> In short, **you can safely audit confidential or pre-release code.**

---

## 📦 Requirements

- **macOS 26 (Tahoe) or later**
- An **Apple-Intelligence-capable Mac** (Apple silicon) with **Apple Intelligence enabled**
  (turn it on under *System Settings → Apple Intelligence & Siri*)
- **Xcode 26 or later** to build (FoundationModels relies on its macros)

---

## 🚀 Installation

### A. Homebrew (recommended — easiest)

Installs with **no certificate and no Gatekeeper warning**.

```bash
# CLI (installed with no Gatekeeper warning)
brew install NagaYu/tap/swiftguard

# Desktop app
brew install --cask --no-quarantine NagaYu/tap/swiftguard
```

Details: [NagaYu/homebrew-tap](https://github.com/NagaYu/homebrew-tap)

### B. Desktop app (manual DMG)

1. Download `SwiftGuard-x.y.z.dmg` from [Releases](https://github.com/NagaYu/SwiftGuard/releases).
2. Open the DMG and drag `SwiftGuard.app` into `Applications`.
3. On first launch, **right-click `SwiftGuard.app` → Open** (the app is unsigned).
4. Drag a folder or file onto the window.

> Building it yourself? See [Building for Distribution](#-building-for-distribution).

### C. CLI (from source)

```bash
git clone https://github.com/NagaYu/SwiftGuard.git
cd SwiftGuard

# Release build
swift build -c release

# Optional: put it on your PATH
cp .build/release/swiftguard /usr/local/bin/
```

---

## 🖥 Usage

### CLI

```bash
# Audit a single file
swiftguard path/to/File.swift

# Recursively audit a directory
swiftguard ./Sources

# Fast verdict only (skip the Markdown review body)
swiftguard --quiet ./Sources

# For CI / hooks: exit code 1 if any critical issue is found
swiftguard --strict ./Sources

# Print the audited dimensions and checklists (no model required)
swiftguard --rules

# Save the report to a Markdown file (plain, no color, when piped)
swiftguard ./Sources > report.md

# Only check whether the on-device model is available (for CI / hooks)
swiftguard --check
```

| Option | Description |
|--------|-------------|
| `--rules` | Print the audited dimensions and checklists, then exit (no model required) |
| `--check` | Check on-device model availability only, then exit (available=`0` / unavailable=`2`) |
| `--quiet` | Skip the Markdown review and show only the risk-level badge (fast) |
| `--strict` | Exit code `1` if any 🔴 CRITICAL issue is found |
| `--no-color` | Disable colored output |
| `--max-chars <n>` | Max characters audited per file (default 8000) |

**Exit codes:** `0` = no critical issues / `1` = critical issue found (`--strict`) / `2` = model unavailable, path error, or no target files

### Desktop app

- **Left pane**: drag & drop `.swift` files or folders (or pick them with a button)
- **Right pane**: streamed, nicely rendered Markdown results — with **Copy** / **Save as Markdown** buttons
- **Bottom**: status text and a progress bar

---

## 🪝 Git pre-commit hook

Automatically block commits that contain dangerous code.

```bash
# Run at the repo root (installs .git/hooks/pre-commit)
./scripts/install-hooks.sh
```

From then on, every `git commit` audits the staged `.swift` files and aborts the commit if a 🔴 CRITICAL issue is found.

```bash
SWIFTGUARD_SKIP=1 git commit ...   # temporarily disable
git commit --no-verify             # skip once
```

> **Behavior notes:** when the on-device model is unavailable, the hook does **not** block the commit (fail-open). The blocking verdict (structured risk assessment) is generated at temperature 0 and treated as 🔴 CRITICAL whenever at least one critical issue is reported, so results are stable across runs for the same code.

---

## 📀 Building for Distribution

Produce `.app` and `.dmg` with a single command.

```bash
./scripts/build.sh         # CLI + .app + .dmg
./scripts/build.sh app     # .app only
./scripts/build.sh dmg     # .app + .dmg
./scripts/build.sh cli     # CLI only
```

Artifacts are written to `dist/` (universal binary: arm64 + x86_64).

### Signing & notarization (optional, for wide distribution)

With nothing configured, builds are **ad-hoc signed** (fine for local use and testing). To distribute without a Gatekeeper warning, sign and notarize with an Apple Developer ID.

```bash
# Sign with a Developer ID (hardened runtime)
SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
  ./scripts/build.sh dmg

# Sign + notarize + staple in one go.
# First store your notarytool credentials:
#   xcrun notarytool store-credentials swiftguard-notary \
#     --apple-id "you@example.com" --team-id TEAMID --password <app-specific-password>
SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
NOTARY_PROFILE="swiftguard-notary" \
  ./scripts/build.sh dmg
```

| Environment variable | Description |
|----------------------|-------------|
| `SIGN_IDENTITY` | Developer ID signing identity (ad-hoc signing if unset) |
| `NOTARY_PROFILE` | Saved `notarytool` profile name (notarize & staple only when set) |

---

## 🏗 Architecture

The AI logic and file scanning are isolated in the shared **`SwiftGuardCore`** module, reused by both the CLI and the GUI.

```
SwiftGuard/
├── Package.swift
├── Sources/
│   ├── SwiftGuardCore/        # 🧠 Shared core (used by CLI & GUI)
│   │   ├── AuditEngine.swift      # FoundationModels calls & streaming
│   │   ├── AuditCategory.swift    # Audit dimensions (checklists)
│   │   ├── AuditPrompt.swift      # Builds system instructions from dimensions
│   │   ├── RiskAssessment.swift   # Structured risk verdict via @Generable
│   │   └── FileScanner.swift      # Recursive .swift file collection
│   ├── swiftguard/            # 💻 CLI (swift-argument-parser)
│   │   ├── SwiftGuardCommand.swift
│   │   └── Terminal.swift         # ANSI colors / separators
│   └── SwiftGuardApp/         # 🖼 SwiftUI desktop app
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

> **Adding a dimension is easy**: append one entry to `AuditCategory.all` in
> `Sources/SwiftGuardCore/AuditCategory.swift`, and it automatically flows into the
> CLI, GUI, and pre-commit prompts.

---

## 🧪 Development

```bash
swift build        # build
swift test         # unit tests
swift run swiftguard ./Examples   # audit the samples

# If only the Command Line Tools are active, point at the Xcode toolchain:
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift build
```

---

## 🤝 Contributing

Issues and PRs are welcome — new or improved audit dimensions (prompts), better output formatting, additional languages, and more. See [CONTRIBUTING.md](CONTRIBUTING.md).

---

## 📄 License

[MIT](LICENSE) © 2026 SwiftGuard Contributors — free for personal and commercial use.
