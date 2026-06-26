import Foundation

final class DownloadManager {
    var onComplete: (() -> Void)?
    var timer: Timer?

    func start() {
        // self を強参照キャプチャ → 循環参照の典型
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { t in
            self.tick()
        }
        onComplete = {
            self.cleanup()
        }
    }

    func tick() {
        // バックグラウンドから UI を直接更新（メインスレッド外）
        DispatchQueue.global().async {
            let data = try! Data(contentsOf: URL(string: "https://example.com")!)
            print("loaded \(data.count) location: \(UserLocation.current)")
        }
    }

    func cleanup() { timer?.invalidate() }
}
