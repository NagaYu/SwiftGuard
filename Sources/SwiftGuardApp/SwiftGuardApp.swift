import SwiftUI

/// SwiftGuard デスクトップアプリのエントリポイント。
@main
struct SwiftGuardApp: App {
    var body: some Scene {
        WindowGroup("SwiftGuard") {
            ContentView()
        }
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .help) {
                Link("SwiftGuard を GitHub で見る",
                     destination: URL(string: "https://github.com/NagaYu/SwiftGuard")!)
            }
        }
    }
}
