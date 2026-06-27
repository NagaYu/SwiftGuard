import ArgumentParser
import Foundation
import SwiftGuardCore

/// SwiftGuard CLI のエントリポイント。
///
/// 単一ファイルまたはディレクトリを受け取り、各 `.swift` ファイルを
/// オンデバイスLLMで監査して結果をストリーミング出力する。
@main
struct SwiftGuardCommand: AsyncParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "swiftguard",
        abstract: "完全ローカルで動く Swift コード安全監査ツール（Apple オンデバイスLLM）",
        discussion: """
        指定したファイル / ディレクトリ内の Swift コードを、循環参照・スレッド安全性・
        パフォーマンス・Apple プライバシー規約の 4 観点で監査します。
        コードは一切外部送信されず、すべて Mac 上で処理されます。
        """,
        version: "0.2.0"
    )

    @Argument(help: "監査対象のファイルまたはディレクトリのパス。")
    var path: String?

    @Flag(name: .long, help: "カラー出力を無効にする。")
    var noColor = false

    @Flag(name: [.short, .long], help: "重大(CRITICAL)な問題が1件でもあれば終了コード1で終わる（CI / フック用）。")
    var strict = false

    @Flag(name: .long, help: "Markdown レビューを出力せず、構造化リスク判定のみ表示する（高速・フック向け）。")
    var quiet = false

    @Option(name: .long, help: "1ファイルあたりの最大監査文字数。")
    var maxChars: Int = 8_000

    @Flag(name: .long, help: "監査する観点とチェックリストを表示して終了する（モデル不要）。")
    var rules = false

    @Flag(name: .long, help: "オンデバイスモデルの利用可否のみ確認して終了する（利用可=0 / 不可=2）。")
    var check = false

    func run() async throws {
        let useColor = !noColor && Terminal.stdoutIsTTY
        let term = Terminal(useColor: useColor)

        // 観点一覧の表示（モデル不要）。
        if rules {
            printRules(term: term)
            return
        }

        // 1. モデル利用可否チェック
        switch AuditEngine.checkAvailability() {
        case .available:
            if check {
                term.print(term.paint("✓ オンデバイスモデルは利用可能です。", .green))
                return
            }
        case .unavailable(let reason):
            Terminal.errorLine(term.paint("✗ オンデバイスモデルを利用できません: ", .red, .bold) + reason)
            throw ExitCode(2)
        }

        // path はレビュー時のみ必須（--check では不要）。
        guard let path else {
            throw ValidationError("監査対象のパスを指定してください（観点一覧は `swiftguard --rules`）。")
        }

        // 2. 対象ファイル収集
        let files: [URL]
        do {
            files = try FileScanner.collectSwiftFiles(at: path)
        } catch {
            Terminal.errorLine(term.paint("✗ \(error)", .red))
            throw ExitCode(2)
        }

        guard !files.isEmpty else {
            // 対象なしはインフラ/使い方の問題として 2（フックを誤ってブロックしない）。
            Terminal.errorLine(term.paint("対象となる .swift ファイルが見つかりませんでした。", .yellow))
            throw ExitCode(2)
        }

        printBanner(term: term, fileCount: files.count)

        let engine = AuditEngine(options: .init(maxCharactersPerFile: maxChars))
        var worstLevel: RiskLevel = .safe

        // 3. 1ファイルずつ監査
        for (index, file) in files.enumerated() {
            let display = relativePath(file)
            printFileHeader(term: term, name: display, index: index + 1, total: files.count)

            let source: String
            do {
                source = try FileScanner.readSource(file)
            } catch {
                Terminal.errorLine(term.paint("  読み込み失敗: \(error)", .red))
                continue
            }

            do {
                if !quiet {
                    // Markdown レビューをストリーミング出力。
                    for try await delta in engine.streamReview(fileName: display, source: source) {
                        term.write(delta)
                    }
                    term.print("\n")
                }

                // 構造化リスク判定（バッジ表示・終了コード判定）。
                let assessment = try await engine.assessRisk(fileName: display, source: source)
                worstLevel = max(worstLevel, assessment.effectiveLevel)
                printVerdict(term: term, assessment: assessment)
            } catch {
                Terminal.errorLine(term.paint("  ⚠️ ", .yellow) + AuditEngine.friendlyMessage(for: error))
            }
        }

        printSummary(term: term, worst: worstLevel)

        if strict, worstLevel.shouldBlockCommit {
            throw ExitCode(1)
        }
    }

    // MARK: - 表示ヘルパー

    private func printBanner(term: Terminal, fileCount: Int) {
        term.print()
        term.print(term.paint("🛡  SwiftGuard", .cyan, .bold) + term.paint("  — 完全ローカル Swift 安全監査", .dim))
        term.print(term.paint("   \(fileCount) 個の Swift ファイルを監査します（コードは外部送信されません）", .gray))
        term.print(term.rule())
    }

    private func printFileHeader(term: Terminal, name: String, index: Int, total: Int) {
        term.print()
        term.print(term.paint("▶ [\(index)/\(total)] ", .blue, .bold) + term.paint(name, .bold))
        term.print(term.rule("┄"))
    }

    private func printVerdict(term: Terminal, assessment: RiskAssessment) {
        let level = assessment.effectiveLevel
        let badge: String
        switch level {
        case .safe: badge = term.paint(" \(level.badge) ", .green, .bold)
        case .warning: badge = term.paint(" \(level.badge) ", .yellow, .bold)
        case .critical: badge = term.paint(" \(level.badge) ", .red, .bold)
        }
        term.print(badge + "  " + assessment.summary)
        if assessment.criticalIssueCount > 0 {
            term.print(term.paint("   重大な問題: \(assessment.criticalIssueCount) 件", .red))
        }
    }

    private func printSummary(term: Terminal, worst: RiskLevel) {
        term.print()
        term.print(term.rule("━"))
        term.print(term.paint("監査完了", .bold) + "  最も深刻なレベル: " + worst.badge)
        term.print()
    }

    private func printRules(term: Terminal) {
        term.print()
        term.print(term.paint("🛡  SwiftGuard が監査する観点", .cyan, .bold))
        term.print(term.rule())
        for (index, category) in AuditPrompt.categories.enumerated() {
            term.print()
            term.print(term.paint("\(index + 1). \(category.emoji) \(category.title)", .bold))
            for item in category.checklist {
                term.print(term.paint("   • ", .gray) + item)
            }
        }
        term.print()
        term.print(term.rule())
        term.print(term.paint("重大度: ", .bold) + "🔴 重大 / 🟡 警告 / 🟢 軽微")
        term.print()
    }

    private func relativePath(_ url: URL) -> String {
        let cwd = FileManager.default.currentDirectoryPath
        if url.path.hasPrefix(cwd + "/") {
            return String(url.path.dropFirst(cwd.count + 1))
        }
        return url.lastPathComponent
    }
}

// RiskLevel を深刻度順に比較できるようにする（summary の最悪値算出用）。
extension RiskLevel: Comparable {
    private var rank: Int {
        switch self {
        case .safe: return 0
        case .warning: return 1
        case .critical: return 2
        }
    }
    public static func < (lhs: RiskLevel, rhs: RiskLevel) -> Bool {
        lhs.rank < rhs.rank
    }
}
