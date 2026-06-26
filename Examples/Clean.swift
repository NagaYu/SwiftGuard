import Foundation

/// 良い実装例（SAFE 判定の確認用）。
/// クロージャは [weak self] でキャプチャし、UI 更新は @MainActor で行う。
@MainActor
final class CounterViewModel {
    private(set) var count = 0
    private let store: CounterStore

    init(store: CounterStore) {
        self.store = store
    }

    func increment() {
        count += 1
    }

    /// 非同期に永続化。self は弱参照でキャプチャし循環参照を避ける。
    func persist() {
        Task { [weak self] in
            guard let self else { return }
            await self.store.save(self.count)
        }
    }
}

/// 並行アクセスを actor で保護した安全なストア。
actor CounterStore {
    private var saved = 0
    func save(_ value: Int) { saved = value }
    func load() -> Int { saved }
}
