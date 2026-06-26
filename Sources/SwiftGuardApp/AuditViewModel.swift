import Foundation
import Observation
import SwiftGuardCore

/// GUI 用の監査オーケストレーション。共通コア `AuditEngine` を呼び出して結果を蓄積する。
@MainActor
@Observable
final class AuditViewModel {

    /// 画面右側に表示する Markdown レビュー全文。
    var reportMarkdown: String = ""

    /// 下部に表示するステータス文言。
    var statusText: String = "Swift ファイルまたはフォルダをドロップして監査を開始"

    /// 進捗（0.0〜1.0）。
    var progress: Double = 0

    /// 監査実行中フラグ。
    var isScanning = false

    /// モデルが使えない場合の理由（nil なら利用可能）。
    var availabilityMessage: String?

    private var currentTask: Task<Void, Never>?
    private let engine = AuditEngine()

    init() {
        refreshAvailability()
    }

    /// オンデバイスモデルの利用可否を更新する。
    func refreshAvailability() {
        switch AuditEngine.checkAvailability() {
        case .available:
            availabilityMessage = nil
        case .unavailable(let reason):
            availabilityMessage = reason
        }
    }

    /// ドロップ／選択された複数パスをまとめて監査する。
    func audit(paths: [String]) {
        guard availabilityMessage == nil else { return }
        cancel()
        reportMarkdown = ""
        progress = 0
        isScanning = true

        currentTask = Task { [engine] in
            // 全パスから対象ファイルを収集。
            var files: [URL] = []
            for path in paths {
                if let found = try? FileScanner.collectSwiftFiles(at: path) {
                    files.append(contentsOf: found)
                }
            }

            guard !files.isEmpty else {
                self.statusText = "対象となる .swift ファイルが見つかりませんでした。"
                self.isScanning = false
                return
            }

            self.append("# 🛡 SwiftGuard 監査レポート\n\n対象: \(files.count) ファイル\n")

            for (index, file) in files.enumerated() {
                if Task.isCancelled { break }
                let name = file.lastPathComponent
                self.statusText = "スキャン中… (\(index + 1)/\(files.count)) \(name)"
                self.append("\n\n---\n\n## 📄 \(name)\n\n")

                do {
                    let source = try FileScanner.readSource(file)
                    for try await delta in engine.streamReview(fileName: name, source: source) {
                        if Task.isCancelled { break }
                        self.append(delta)
                    }
                } catch {
                    self.append("\n> ⚠️ 監査エラー: \(error)\n")
                }

                self.progress = Double(index + 1) / Double(files.count)
            }

            self.statusText = Task.isCancelled
                ? "キャンセルしました"
                : "完了 — \(files.count) ファイルを監査しました"
            self.isScanning = false
        }
    }

    /// 実行中の監査を中断する。
    func cancel() {
        currentTask?.cancel()
        currentTask = nil
        isScanning = false
    }

    private func append(_ text: String) {
        reportMarkdown += text
    }
}
