import Foundation

/// 監査対象の `.swift` ファイルを収集するスキャナ。
///
/// 単一ファイル・ディレクトリのどちらにも対応し、ディレクトリは再帰的に走査する。
/// ビルド成果物や依存物のディレクトリは自動的に除外する。
public enum FileScanner {

    /// 走査時に丸ごとスキップするディレクトリ名。
    public static let ignoredDirectories: Set<String> = [
        ".build", ".git", "DerivedData", "Pods", "Carthage",
        ".swiftpm", "node_modules", ".vscode", "vendor",
    ]

    /// スキャン中に発生し得るエラー。
    public enum ScanError: Error, CustomStringConvertible {
        case pathNotFound(String)
        case notSwiftFile(String)
        case unreadable(String)

        public var description: String {
            switch self {
            case .pathNotFound(let p): return "パスが見つかりません: \(p)"
            case .notSwiftFile(let p): return "Swift ファイルではありません: \(p)"
            case .unreadable(let p): return "ファイルを読み込めません: \(p)"
            }
        }
    }

    /// 指定パス配下の監査対象 `.swift` ファイル一覧を返す。
    /// - Parameter path: ファイルまたはディレクトリのパス。
    /// - Returns: ソート済みのファイル URL 配列。
    public static func collectSwiftFiles(at path: String) throws -> [URL] {
        let fm = FileManager.default
        let expanded = (path as NSString).expandingTildeInPath
        let url = URL(fileURLWithPath: expanded)

        var isDirectory: ObjCBool = false
        guard fm.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
            throw ScanError.pathNotFound(path)
        }

        // 単一ファイル指定。
        if !isDirectory.boolValue {
            guard url.pathExtension == "swift" else {
                throw ScanError.notSwiftFile(path)
            }
            return [url]
        }

        // ディレクトリ → 再帰走査。
        var results: [URL] = []
        guard let enumerator = fm.enumerator(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            throw ScanError.unreadable(path)
        }

        for case let fileURL as URL in enumerator {
            // 除外ディレクトリは丸ごとスキップ。
            if ignoredDirectories.contains(fileURL.lastPathComponent) {
                enumerator.skipDescendants()
                continue
            }
            if fileURL.pathExtension == "swift" {
                results.append(fileURL)
            }
        }
        return results.sorted { $0.path < $1.path }
    }

    /// ファイル内容を読み込む。
    public static func readSource(_ url: URL) throws -> String {
        do {
            return try String(contentsOf: url, encoding: .utf8)
        } catch {
            throw ScanError.unreadable(url.path)
        }
    }
}
