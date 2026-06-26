import SwiftUI
import UniformTypeIdentifiers

/// メイン画面。左: ドロップ/選択エリア、右: 監査結果、下: ステータス＋進捗バー。
struct ContentView: View {
    @State private var model = AuditViewModel()
    @State private var isDropTargeted = false

    var body: some View {
        VStack(spacing: 0) {
            HSplitView {
                dropPane
                    .frame(minWidth: 240, idealWidth: 300, maxWidth: 420)
                resultPane
                    .frame(minWidth: 420)
            }
            Divider()
            statusBar
        }
        .frame(minWidth: 820, minHeight: 560)
    }

    // MARK: - 左ペイン（入力）

    private var dropPane: some View {
        VStack(spacing: 16) {
            if let message = model.availabilityMessage {
                unavailableBanner(message)
            }

            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(
                        style: StrokeStyle(lineWidth: 2, dash: [8, 6])
                    )
                    .foregroundStyle(isDropTargeted ? Color.accentColor : Color.secondary.opacity(0.5))
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(isDropTargeted ? Color.accentColor.opacity(0.08) : Color.clear)
                    )

                VStack(spacing: 12) {
                    Image(systemName: "shield.lefthalf.filled")
                        .font(.system(size: 44))
                        .foregroundStyle(Color.accentColor)
                    Text("ここに .swift ファイル／フォルダをドロップ")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    Text("コードは外部送信されません（完全ローカル監査）")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button("ファイル／フォルダを選択…", action: chooseFiles)
                        .buttonStyle(.borderedProminent)
                        .disabled(model.isScanning || model.availabilityMessage != nil)
                }
                .padding()
            }
            .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
                handleDrop(providers)
            }

            if model.isScanning {
                Button(role: .cancel) {
                    model.cancel()
                } label: {
                    Label("キャンセル", systemImage: "stop.circle")
                }
            }
        }
        .padding()
    }

    private func unavailableBanner(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("オンデバイスモデルを利用できません", systemImage: "exclamationmark.triangle.fill")
                .font(.subheadline.bold())
                .foregroundStyle(.orange)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - 右ペイン（結果）

    private var resultPane: some View {
        ScrollViewReader { proxy in
            ScrollView {
                Group {
                    if model.reportMarkdown.isEmpty {
                        emptyState
                    } else {
                        MarkdownView(markdown: model.reportMarkdown)
                            .padding()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Color.clear.frame(height: 1).id("bottom")
            }
            .onChange(of: model.reportMarkdown) {
                // ストリーミング中は常に末尾へ追従。
                if model.isScanning {
                    withAnimation(.linear(duration: 0.1)) {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
            }
        }
        .background(Color(nsColor: .textBackgroundColor))
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("監査結果がここに表示されます")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 400)
    }

    // MARK: - 下部ステータスバー

    private var statusBar: some View {
        HStack(spacing: 12) {
            if model.isScanning {
                ProgressView()
                    .controlSize(.small)
            }
            Text(model.statusText)
                .font(.callout)
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer()
            ProgressView(value: model.progress)
                .frame(width: 180)
                .opacity(model.isScanning || model.progress > 0 ? 1 : 0.3)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.bar)
    }

    // MARK: - 入力処理

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        // 各 provider から URL を非同期で取り出し、出揃ったらまとめて監査する。
        let collector = DropCollector(expected: providers.count) { paths in
            if !paths.isEmpty { model.audit(paths: paths) }
        }
        for provider in providers {
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                collector.add(url?.path)
            }
        }
        return true
    }

    private func chooseFiles() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.allowedContentTypes = [.swiftSource, .folder]
        panel.prompt = "監査"
        if panel.runModal() == .OK {
            model.audit(paths: panel.urls.map(\.path))
        }
    }
}

/// 複数の `NSItemProvider` から非同期に集まるパスをスレッドセーフに集約するヘルパー。
private final class DropCollector: @unchecked Sendable {
    private let lock = NSLock()
    private var paths: [String] = []
    private var remaining: Int
    private let completion: @MainActor ([String]) -> Void

    init(expected: Int, completion: @escaping @MainActor ([String]) -> Void) {
        self.remaining = max(expected, 0)
        self.completion = completion
        if expected <= 0 { finish(with: []) }
    }

    func add(_ path: String?) {
        lock.lock()
        if let path { paths.append(path) }
        remaining -= 1
        let done = remaining <= 0
        let snapshot = paths
        lock.unlock()
        if done { finish(with: snapshot) }
    }

    private func finish(with snapshot: [String]) {
        let completion = self.completion
        Task { @MainActor in completion(snapshot) }
    }
}

private extension UTType {
    /// `.swift` ソースファイルの型。環境に無い場合のフォールバック付き。
    static var swiftSource: UTType {
        UTType(filenameExtension: "swift") ?? .sourceCode
    }
}
