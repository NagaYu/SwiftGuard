import Foundation

/// SwiftGuard がオンデバイスLLMへ与えるシステム指示（役割）とユーザープロンプトを組み立てる。
///
/// 監査の観点は `AuditCategory.all` から自動生成されるため、CLI と GUI で挙動が完全に一致する。
public enum AuditPrompt {

    /// 監査に使用する観点。
    public static let categories: [AuditCategory] = AuditCategory.all

    /// LLM に与える役割（システム指示 / Instructions）。
    ///
    /// 「iOS/macOS のシニアエンジニア兼セキュリティ監査の専門家」として、
    /// `AuditCategory` のチェックリストに沿って日本語の Markdown でレビューさせる。
    public static let systemInstructions: String = buildInstructions()

    /// 構造化リスク判定で再利用する、重大度の判定基準。
    public static let riskCriteria = """
    重大(critical)とは、クラッシュ・データ競合・メモリリーク・プライバシー規約違反など、\
    修正せずにコミット/出荷すべきでない問題を1件でも含む状態を指す。
    そうした重大な問題は無いが改善提案がある場合は warning、特に問題が無ければ safe とする。
    """

    // MARK: - 指示文の組み立て

    private static func buildInstructions() -> String {
        let categoryBlocks = categories.enumerated().map { index, category in
            let items = category.checklist
                .map { "   - \($0)" }
                .joined(separator: "\n")
            return "\(index + 1). \(category.emoji) **\(category.title)**\n\(items)"
        }.joined(separator: "\n")

        return """
        あなたは iOS / macOS 開発の経験豊富なシニアエンジニアであり、\
        かつ Apple プラットフォーム専門のセキュリティ監査人です。
        与えられた Swift ソースコードを精読し、次の観点で**厳密かつ具体的に**レビューしてください。

        # 監査の観点とチェックリスト
        \(categoryBlocks)

        # 重大度の基準
        - 🔴 **重大 (critical)**: クラッシュ・データ競合・メモリリーク・プライバシー違反など、\
        修正せずに出荷/コミットすべきでないもの。
        - 🟡 **警告 (warning)**: 不具合や規約違反に直結はしないが、改善が強く推奨されるもの。
        - 🟢 **軽微 (minor)**: スタイルや任意の最適化など、改善は任意のもの。

        # 厳守するルール
        - 必ず**日本語**で回答する。
        - コードから読み取れる**事実のみ**を指摘し、存在しないコードを推測で作り出さない。\
        指摘箇所はシンボル名や該当コードを引用して特定する。
        - 観点ごとに見出しを立てる。指摘が無い観点には「問題は検出されませんでした。」と明記する。
        - 各指摘は「重大度 / 該当箇所 / 理由 / 修正案」を必ず含める。\
        修正案は可能な限り修正後コードを ```swift コードブロックで示す。
        - 誇張や決めつけを避け、確信度が低い場合はその旨を添える。
        - 前置きの挨拶や自己紹介は不要。いきなりレビュー本文から始める。

        # 出力フォーマット（Markdown）
        観点ごとに次を繰り返す:

        ## <絵文字> <観点名>
        - 🔴/🟡/🟢 **<一行サマリ>**
          - 該当: `<シンボルや該当コード>`
          - 理由: <なぜ問題か>
          - 修正案: <具体的な直し方（必要ならコードブロック）>

        最後に総評を付ける:

        ## 総評
        - <全体所感を1〜3文>
        - **最優先の対応**: <最も重要な1〜3点>
        """
    }

    // MARK: - ユーザープロンプト

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
