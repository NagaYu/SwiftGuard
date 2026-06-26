import Foundation

/// SwiftGuard がオンデバイスLLMへ与えるシステム指示（役割）とユーザープロンプトを組み立てる。
///
/// すべての文章を一箇所に集約することで、CLI と GUI で監査の挙動を完全に一致させる。
public enum AuditPrompt {

    /// LLM に与える役割（システム指示 / Instructions）。
    ///
    /// 「iOS/macOS のシニアエンジニア兼セキュリティ監査の専門家」として、
    /// 4 つの観点（循環参照・スレッド安全性・パフォーマンス・プライバシー規約）を
    /// 日本語の Markdown でレビューさせる。
    public static let systemInstructions = """
    あなたは iOS / macOS 開発における経験豊富なシニアエンジニアであり、\
    かつ Apple プラットフォーム専門のセキュリティ監査人です。
    与えられた Swift ソースコードを精読し、以下の 4 つの観点で厳密にレビューしてください。

    1. **循環参照 / メモリリーク**: `self` の強参照キャプチャ、`delegate` の `weak` 漏れ、
       クロージャ・`Task`・`Timer`・`NotificationCenter` による retain cycle を指摘する。
       修正例（`[weak self]` / `unowned` / `weak var` 等）を示す。
    2. **スレッド安全性 / 並行性**: データ競合、`@MainActor` 違反、UI 更新のメインスレッド外実行、
       非 `Sendable` 型の越境、`DispatchQueue` の誤用、`actor` 化が望ましい箇所を指摘する。
    3. **パフォーマンスの無駄**: 不要なコピー、メインスレッドのブロッキングI/O、O(n^2) ループ、
       過剰なオブジェクト生成、再描画コスト、`lazy`/キャッシュで改善できる箇所を指摘する。
    4. **Apple プライバシー規約違反のリスク**: 許可なしの位置情報・連絡先・写真・マイク等へのアクセス、
       IDFA / フィンガープリンティング、機微情報のログ出力・平文保存・外部送信、
       `Info.plist` の利用目的文字列の欠如など、App Store 審査で問題になり得る点を指摘する。

    # 出力ルール
    - 必ず**日本語**で回答する。
    - 読みやすい **Markdown** で出力する（見出し `##`、箇条書き、コードブロックを活用）。
    - 観点ごとに見出しを立て、指摘が無い観点には「問題は検出されませんでした。」と明記する。
    - 各指摘には「重大度（🔴重大 / 🟡警告 / 🟢軽微）」と「該当箇所の概要」「理由」「修正案」を含める。
    - 推測で断定せず、コードから読み取れる事実に基づいて指摘する。
    - 最後に `## 総評` として全体の要約と、最も優先すべき対応を 1〜3 点挙げる。
    - 前置きの挨拶や自己紹介は不要。いきなりレビュー本文から始める。
    """

    /// 1ファイル分のレビューを依頼するユーザープロンプトを生成する。
    /// - Parameters:
    ///   - fileName: 対象ファイル名（パス）。文脈として LLM に渡す。
    ///   - source: ソースコード本文。
    ///   - maxCharacters: LLM のコンテキスト上限に収めるための最大文字数。超過分は切り詰める。
    /// - Returns: プロンプト文字列と、切り詰めが発生したかどうか。
    public static func reviewPrompt(
        fileName: String,
        source: String,
        maxCharacters: Int = 12_000
    ) -> (prompt: String, truncated: Bool) {
        let truncated = source.count > maxCharacters
        let body = truncated ? String(source.prefix(maxCharacters)) : source
        let notice = truncated
            ? "\n\n（注: ファイルが長いため先頭 \(maxCharacters) 文字のみを監査対象としています）"
            : ""

        let prompt = """
        次の Swift ファイル「\(fileName)」を監査してください。\(notice)

        ```swift
        \(body)
        ```
        """
        return (prompt, truncated)
    }
}
