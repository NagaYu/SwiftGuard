import Foundation
import Testing
@testable import SwiftGuardCore

@Suite("FileScanner")
struct FileScannerTests {

    /// 一時ディレクトリにダミーのファイル群を作って後始末するヘルパー。
    private func withTempTree(_ body: (URL) throws -> Void) throws {
        let fm = FileManager.default
        let root = fm.temporaryDirectory.appendingPathComponent("swiftguard-test-\(UUID().uuidString)")
        try fm.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: root) }
        try body(root)
    }

    @Test("単一の .swift ファイルを1件返す")
    func singleSwiftFile() throws {
        try withTempTree { root in
            let file = root.appendingPathComponent("A.swift")
            try "let a = 1".write(to: file, atomically: true, encoding: .utf8)

            let result = try FileScanner.collectSwiftFiles(at: file.path)
            #expect(result.count == 1)
            #expect(result.first?.lastPathComponent == "A.swift")
        }
    }

    @Test(".swift 以外の単一ファイルはエラー")
    func nonSwiftFileThrows() throws {
        try withTempTree { root in
            let file = root.appendingPathComponent("readme.md")
            try "# hi".write(to: file, atomically: true, encoding: .utf8)
            #expect(throws: FileScanner.ScanError.self) {
                _ = try FileScanner.collectSwiftFiles(at: file.path)
            }
        }
    }

    @Test("ディレクトリを再帰走査し .build は除外する")
    func recursiveScanIgnoresBuildDir() throws {
        try withTempTree { root in
            let fm = FileManager.default
            let sub = root.appendingPathComponent("Sources/App")
            try fm.createDirectory(at: sub, withIntermediateDirectories: true)
            try "let a = 1".write(to: sub.appendingPathComponent("A.swift"), atomically: true, encoding: .utf8)
            try "let b = 2".write(to: root.appendingPathComponent("B.swift"), atomically: true, encoding: .utf8)

            // 除外されるべきディレクトリ
            let build = root.appendingPathComponent(".build")
            try fm.createDirectory(at: build, withIntermediateDirectories: true)
            try "let c = 3".write(to: build.appendingPathComponent("C.swift"), atomically: true, encoding: .utf8)

            let result = try FileScanner.collectSwiftFiles(at: root.path)
            let names = result.map(\.lastPathComponent).sorted()
            #expect(names == ["A.swift", "B.swift"])
        }
    }

    @Test("存在しないパスはエラー")
    func missingPathThrows() {
        #expect(throws: FileScanner.ScanError.self) {
            _ = try FileScanner.collectSwiftFiles(at: "/no/such/path/xyz123")
        }
    }
}
