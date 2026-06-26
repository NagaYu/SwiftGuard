import Foundation
import FoundationModels

/// ファイル単位のリスク総合判定レベル。
///
/// `@Generable` によりオンデバイスLLMが構造化出力として直接生成できる。
/// CLI の終了コードや pre-commit フックのブロック判定に使用する。
@Generable
public enum RiskLevel: Equatable {
    /// 重大な問題は検出されなかった。
    case safe
    /// 軽微〜中程度の改善点がある（コミットは可能）。
    case warning
    /// コミットをブロックすべき重大な問題がある。
    case critical
}

/// LLM が返す構造化されたリスク評価。
@Generable
public struct RiskAssessment: Equatable {
    /// このファイルの総合リスクレベル。
    @Guide(description: "ファイル全体の総合的なリスクレベル。重大な循環参照・データ競合・プライバシー違反があれば critical。")
    public var level: RiskLevel

    /// 判定理由の短い要約（日本語・1〜2文）。
    @Guide(description: "判定理由を日本語で1〜2文に要約する。")
    public var summary: String

    /// 検出した重大（critical）級の問題の件数。
    @Guide(description: "コミットをブロックすべき重大な問題の件数。0以上の整数。")
    public var criticalIssueCount: Int
}

extension RiskLevel {
    /// 端末表示用のバッジ文字列。
    public var badge: String {
        switch self {
        case .safe: return "🟢 SAFE"
        case .warning: return "🟡 WARNING"
        case .critical: return "🔴 CRITICAL"
        }
    }

    /// pre-commit でコミットをブロックすべきか。
    public var shouldBlockCommit: Bool {
        self == .critical
    }
}
