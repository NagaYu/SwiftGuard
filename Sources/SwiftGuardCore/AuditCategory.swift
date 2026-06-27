import Foundation

/// 監査の「観点」を表す構造化データ。
///
/// プロンプト（システム指示）はこの定義から自動生成されるため、
/// 新しい観点を追加したい場合は `AuditCategory.all` に 1 要素加えるだけで
/// CLI・GUI・pre-commit すべてに反映される。
public struct AuditCategory: Sendable, Identifiable, Equatable {
    /// 安定した識別子（英小文字）。
    public let id: String
    /// 表示用の絵文字。
    public let emoji: String
    /// 観点名（日本語）。
    public let title: String
    /// この観点で重点的に確認すべき具体的なチェック項目。
    public let checklist: [String]

    public init(id: String, emoji: String, title: String, checklist: [String]) {
        self.id = id
        self.emoji = emoji
        self.title = title
        self.checklist = checklist
    }
}

extension AuditCategory {

    /// 🔁 循環参照 / メモリリーク
    public static let memorySafety = AuditCategory(
        id: "memory",
        emoji: "🔁",
        title: "循環参照 / メモリリーク",
        checklist: [
            "クロージャ内の `self` 強参照（`[weak self]` / `[unowned self]` の欠如）",
            "`Timer` / `DispatchSourceTimer` / `CADisplayLink` の自己参照による retain cycle",
            "`Task {}` が `self` を強くキャプチャし、解放を妨げているケース",
            "`delegate` が `weak` でない、または親子オブジェクトが相互に強参照している",
            "`NotificationCenter` / KVO / Combine の購読が解除されず保持され続ける",
        ]
    )

    /// 🧵 スレッド安全性 / 並行性
    public static let concurrency = AuditCategory(
        id: "concurrency",
        emoji: "🧵",
        title: "スレッド安全性 / 並行性",
        checklist: [
            "複数スレッドからの可変状態への保護されないアクセス（データ競合）",
            "`@MainActor` を要する UI / `@Published` 更新がバックグラウンドで実行されている",
            "非 `Sendable` 型が `Task` / `actor` などの並行境界を越えている",
            "`DispatchQueue.*.sync` やセマフォによるデッドロックの恐れ",
            "`actor` 化・直列キュー・ロックで保護すべき共有状態の欠如",
        ]
    )

    /// ⚡️ パフォーマンスの無駄
    public static let performance = AuditCategory(
        id: "performance",
        emoji: "⚡️",
        title: "パフォーマンスの無駄",
        checklist: [
            "メインスレッドでの同期 I/O（`Data(contentsOf:)`・同期ネットワーク/ファイル）",
            "O(n^2) 以上のループや、ループ内の重い再計算・再確保",
            "大きな `struct` / `Array` の不要な値コピー（参照・`inout` で回避可能）",
            "毎回生成している重いオブジェクト（`DateFormatter`・正規表現等）のキャッシュ漏れ",
            "SwiftUI の不要な再描画を招く実装（`body` 内の重い処理・不安定な `id`）",
        ]
    )

    /// 🔐 Apple プライバシー規約違反のリスク
    public static let privacy = AuditCategory(
        id: "privacy",
        emoji: "🔐",
        title: "Apple プライバシー規約違反のリスク",
        checklist: [
            "許可なしの位置情報・連絡先・写真・カメラ・マイク・ヘルスケアへのアクセス",
            "必要な `Info.plist` 利用目的文字列（`NS...UsageDescription`）の欠如",
            "個人情報・トークン・パスワードの平文ログ出力（`print`/`NSLog`）や平文保存",
            "IDFA / デバイスフィンガープリンティング / 不透明なトラッキング",
            "機微情報の外部送信、または `UserDefaults` 保存（Keychain を使うべき箇所）",
        ]
    )

    /// 💥 強制アンラップ / クラッシュ耐性
    public static let crashSafety = AuditCategory(
        id: "crash",
        emoji: "💥",
        title: "強制アンラップ / クラッシュ耐性",
        checklist: [
            "強制アンラップ `!` が nil で実行時クラッシュし得る箇所",
            "`try!` / `as!` によるクラッシュのリスク（安全な `try?` / `as?` で代替可能か）",
            "配列・文字列の範囲外アクセス（`array[i]` の境界チェック欠如）",
            "`fatalError` / `preconditionFailure` が本番経路で発火し得る設計",
            "暗黙的アンラップ Optional（`var x: T!`）の不用意な使用",
        ]
    )

    /// 🧯 エラーハンドリング
    public static let errorHandling = AuditCategory(
        id: "error",
        emoji: "🧯",
        title: "エラーハンドリング",
        checklist: [
            "`try?` でエラーを握りつぶし、失敗が無視されている",
            "空の `catch {}` など、エラーを無視するハンドリング",
            "エラーをログのみで黙殺し、呼び出し側へ伝播していない",
            "`throws` / `Result` で表現すべき失敗を `nil` や真偽値で潰している",
            "ユーザーに通知すべきエラーが UI に反映されない",
        ]
    )

    /// 監査に使用する観点の一覧（順序は出力順）。
    public static let all: [AuditCategory] = [
        memorySafety, concurrency, performance, privacy, crashSafety, errorHandling,
    ]
}
