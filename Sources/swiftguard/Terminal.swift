import Foundation

/// 端末出力のための ANSI カラー / 装飾ヘルパー。
///
/// 出力先がパイプ・リダイレクトの場合や `--no-color` 指定時は自動的に無色化する。
struct Terminal {
    let useColor: Bool

    init(useColor: Bool) {
        self.useColor = useColor
    }

    /// 標準出力が TTY かどうか（パイプ時は false）。
    static var stdoutIsTTY: Bool {
        isatty(fileno(stdout)) == 1
    }

    enum Style: String {
        case reset = "\u{1B}[0m"
        case bold = "\u{1B}[1m"
        case dim = "\u{1B}[2m"
        case red = "\u{1B}[31m"
        case green = "\u{1B}[32m"
        case yellow = "\u{1B}[33m"
        case blue = "\u{1B}[34m"
        case magenta = "\u{1B}[35m"
        case cyan = "\u{1B}[36m"
        case gray = "\u{1B}[90m"
    }

    func paint(_ text: String, _ styles: Style...) -> String {
        guard useColor, !styles.isEmpty else { return text }
        let prefix = styles.map(\.rawValue).joined()
        return prefix + text + Style.reset.rawValue
    }

    /// 画面幅いっぱいの区切り線。
    func rule(_ char: String = "─") -> String {
        let width = Self.columns
        return paint(String(repeating: char, count: width), .gray)
    }

    /// 端末の桁数（取得できなければ 72）。
    static var columns: Int {
        var w = winsize()
        if ioctl(STDOUT_FILENO, TIOCGWINSZ, &w) == 0, w.ws_col > 0 {
            return min(Int(w.ws_col), 100)
        }
        if let env = ProcessInfo.processInfo.environment["COLUMNS"], let c = Int(env) {
            return c
        }
        return 72
    }

    // MARK: - 即時書き込み（ストリーミング用）

    /// バッファリングせず即座に標準出力へ書き込む（“打ち込まれていく”表示用）。
    func write(_ text: String) {
        FileHandle.standardOutput.write(Data(text.utf8))
    }

    func print(_ text: String = "") {
        Swift.print(text)
    }

    /// 標準エラーへ出力。
    static func errorLine(_ text: String) {
        FileHandle.standardError.write(Data((text + "\n").utf8))
    }
}
