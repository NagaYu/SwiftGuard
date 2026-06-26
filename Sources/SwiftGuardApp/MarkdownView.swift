import SwiftUI

/// 依存ライブラリなしで Markdown を見やすく描画する軽量ビュー。
///
/// 見出し・箇条書き・コードブロック・水平線・インライン装飾（太字/コード）に対応。
/// ストリーミングで増えていくテキストにも追従できるよう、行単位で描画する。
struct MarkdownView: View {
    let markdown: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                block.view
            }
        }
        .textSelection(.enabled)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var blocks: [Block] {
        Block.parse(markdown)
    }
}

/// Markdown の 1 ブロック。
private enum Block {
    case heading(level: Int, text: String)
    case bullet(text: String)
    case code(String)
    case rule
    case paragraph(String)

    @ViewBuilder var view: some View {
        switch self {
        case .heading(let level, let text):
            Text(inline(text))
                .font(headingFont(level))
                .fontWeight(.bold)
                .padding(.top, level <= 2 ? 8 : 4)
        case .bullet(let text):
            HStack(alignment: .top, spacing: 8) {
                Text("•").foregroundStyle(.secondary)
                Text(inline(text))
            }
            .padding(.leading, 4)
        case .code(let body):
            Text(body)
                .font(.system(.callout, design: .monospaced))
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondary.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 6))
        case .rule:
            Divider().padding(.vertical, 4)
        case .paragraph(let text):
            Text(inline(text))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func headingFont(_ level: Int) -> Font {
        switch level {
        case 1: return .title
        case 2: return .title2
        case 3: return .title3
        default: return .headline
        }
    }

    /// インライン Markdown（**太字**, `code`, *斜体*）を AttributedString で解釈。
    private func inline(_ text: String) -> AttributedString {
        (try? AttributedString(
            markdown: text,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        )) ?? AttributedString(text)
    }

    /// 全文を行単位でブロックへ分解する。
    static func parse(_ markdown: String) -> [Block] {
        var blocks: [Block] = []
        var inCode = false
        var codeBuffer: [String] = []

        for rawLine in markdown.components(separatedBy: "\n") {
            let line = rawLine

            // コードフェンス開始/終了
            if line.trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                if inCode {
                    blocks.append(.code(codeBuffer.joined(separator: "\n")))
                    codeBuffer.removeAll()
                }
                inCode.toggle()
                continue
            }
            if inCode {
                codeBuffer.append(line)
                continue
            }

            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }

            if trimmed == "---" || trimmed == "***" {
                blocks.append(.rule)
            } else if let heading = headingLevel(trimmed) {
                blocks.append(.heading(level: heading.level, text: heading.text))
            } else if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
                blocks.append(.bullet(text: String(trimmed.dropFirst(2))))
            } else {
                blocks.append(.paragraph(trimmed))
            }
        }
        // 未閉のコードブロック（ストリーミング途中）も表示する。
        if !codeBuffer.isEmpty {
            blocks.append(.code(codeBuffer.joined(separator: "\n")))
        }
        return blocks
    }

    private static func headingLevel(_ line: String) -> (level: Int, text: String)? {
        var level = 0
        var idx = line.startIndex
        while idx < line.endIndex, line[idx] == "#", level < 6 {
            level += 1
            idx = line.index(after: idx)
        }
        guard level > 0, idx < line.endIndex, line[idx] == " " else { return nil }
        return (level, String(line[line.index(after: idx)...]))
    }
}
