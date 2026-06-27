import Foundation
import FoundationModels

/// オンデバイスLLM（Apple FoundationModels）による Swift コード監査エンジン。
///
/// CLI・GUI の双方から共通利用される。ソースコードは一切外部送信されず、
/// すべて Mac 上のオンデバイスモデル（必要に応じて Private Cloud Compute）で処理される。
public struct AuditEngine: Sendable {

    /// モデルの利用可否。
    public enum Availability: Sendable, Equatable {
        case available
        case unavailable(reason: String)
    }

    /// 監査時の生成パラメータ。
    public struct Options: Sendable {
        /// 1ファイルあたりに監査対象とする最大文字数。
        public var maxCharactersPerFile: Int
        /// 生成温度（0に近いほど決定的で監査向き）。
        public var temperature: Double

        public init(maxCharactersPerFile: Int = 8_000, temperature: Double = 0.2) {
            self.maxCharactersPerFile = maxCharactersPerFile
            self.temperature = temperature
        }

        public static let `default` = Options()
    }

    public var options: Options

    public init(options: Options = .default) {
        self.options = options
    }

    // MARK: - 利用可否チェック

    /// 現在の Mac でオンデバイスモデルが利用可能かを判定する。
    public static func checkAvailability() -> Availability {
        switch SystemLanguageModel.default.availability {
        case .available:
            return .available
        case .unavailable(let reason):
            return .unavailable(reason: describe(reason))
        @unknown default:
            return .unavailable(reason: "不明な理由でモデルを利用できません。")
        }
    }

    private static func describe(
        _ reason: SystemLanguageModel.Availability.UnavailableReason
    ) -> String {
        switch reason {
        case .deviceNotEligible:
            return "このデバイスは Apple Intelligence に対応していません。"
        case .appleIntelligenceNotEnabled:
            return "Apple Intelligence が有効化されていません。設定 > Apple Intelligence から有効にしてください。"
        case .modelNotReady:
            return "モデルがまだ準備中です（ダウンロード中など）。しばらく待って再試行してください。"
        @unknown default:
            return "オンデバイスモデルを利用できません。"
        }
    }

    // MARK: - ストリーミング監査

    /// 1ファイルを監査し、生成テキストの「差分（追記分）」を逐次返す非同期ストリーム。
    ///
    /// ターミナルや UI で“打ち込まれていく”表示にするため、累積ではなく差分を yield する。
    /// - Parameters:
    ///   - fileName: 対象ファイル名（LLM への文脈）。
    ///   - source: ソースコード本文。
    /// - Returns: 追記テキストの `AsyncThrowingStream`。
    public func streamReview(
        fileName: String,
        source: String
    ) -> AsyncThrowingStream<String, Error> {
        let opts = options
        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let session = LanguageModelSession(
                        instructions: AuditPrompt.systemInstructions
                    )
                    let built = AuditPrompt.reviewPrompt(
                        fileName: fileName,
                        source: source,
                        maxCharacters: opts.maxCharactersPerFile
                    )
                    let genOptions = GenerationOptions(temperature: opts.temperature)
                    let stream = session.streamResponse(to: built.prompt, options: genOptions)

                    // FoundationModels は累積スナップショットを返すため、差分だけを取り出す。
                    var emitted = ""
                    for try await snapshot in stream {
                        let full = snapshot.content
                        if full.hasPrefix(emitted) {
                            let delta = String(full.dropFirst(emitted.count))
                            if !delta.isEmpty { continuation.yield(delta) }
                        } else {
                            // まれに前方一致しない場合は全文を作り直す。
                            continuation.yield("\n" + full)
                        }
                        emitted = full
                    }
                    continuation.finish()
                } catch is CancellationError {
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// 1ファイルを監査し、完成した Markdown レビュー全文を一括で返す（非ストリーミング）。
    public func review(fileName: String, source: String) async throws -> String {
        let session = LanguageModelSession(instructions: AuditPrompt.systemInstructions)
        let built = AuditPrompt.reviewPrompt(
            fileName: fileName,
            source: source,
            maxCharacters: options.maxCharactersPerFile
        )
        let response = try await session.respond(
            to: built.prompt,
            options: GenerationOptions(temperature: options.temperature)
        )
        return response.content
    }

    // MARK: - 構造化リスク判定（終了コード / pre-commit 用）

    /// 1ファイルの総合リスクを構造化データとして取得する。
    public func assessRisk(fileName: String, source: String) async throws -> RiskAssessment {
        let session = LanguageModelSession(instructions: AuditPrompt.systemInstructions)
        let built = AuditPrompt.reviewPrompt(
            fileName: fileName,
            source: source,
            maxCharacters: options.maxCharactersPerFile
        )
        let prompt = built.prompt + """


        上記コードのレビュー結果を踏まえ、ファイル全体の総合的なリスクレベルを判定してください。
        \(AuditPrompt.riskCriteria)
        """
        let response = try await session.respond(
            to: prompt,
            generating: RiskAssessment.self,
            options: GenerationOptions(temperature: options.temperature)
        )
        return response.content
    }
}
