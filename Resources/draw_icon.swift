// SwiftGuard アプリアイコン生成器（依存ライブラリなし / AppKit のみ）
//
//   swift Resources/draw_icon.swift Resources/icon_1024.png
//
// 1024x1024 の PNG を出力する。実際の .icns 化は scripts/generate-icon.sh が行う。

import AppKit
import Foundation

let outputPath = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "icon_1024.png"

let size: CGFloat = 1024

guard let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(size), pixelsHigh: Int(size),
    bitsPerSample: 8, samplesPerPixel: 4,
    hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0, bitsPerPixel: 0
) else {
    fatalError("ビットマップを作成できませんでした")
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

let cx = size / 2
let cy = size / 2

// ── 背景: macOS 風の角丸スクエア + 青→藍のグラデーション ──
let inset: CGFloat = 80
let bgRect = NSRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2)
let bgPath = NSBezierPath(roundedRect: bgRect, xRadius: (size - inset * 2) * 0.22, yRadius: (size - inset * 2) * 0.22)

let topColor = NSColor(calibratedRed: 0.20, green: 0.46, blue: 0.96, alpha: 1.0)   // ブルー
let bottomColor = NSColor(calibratedRed: 0.36, green: 0.24, blue: 0.86, alpha: 1.0) // インディゴ
let gradient = NSGradient(starting: topColor, ending: bottomColor)!
gradient.draw(in: bgPath, angle: -90)

// ── 盾（シールド）を白で描画 ──
let w: CGFloat = 380
let h: CGFloat = 470
let top = cy + h / 2
let bottom = cy - h / 2

let shield = NSBezierPath()
shield.move(to: NSPoint(x: cx - w / 2, y: top))
shield.line(to: NSPoint(x: cx + w / 2, y: top))
// 右肩 → 底の頂点
shield.curve(
    to: NSPoint(x: cx, y: bottom),
    controlPoint1: NSPoint(x: cx + w / 2, y: cy - h * 0.12),
    controlPoint2: NSPoint(x: cx + w * 0.30, y: bottom + h * 0.04)
)
// 底の頂点 → 左肩
shield.curve(
    to: NSPoint(x: cx - w / 2, y: top),
    controlPoint1: NSPoint(x: cx - w * 0.30, y: bottom + h * 0.04),
    controlPoint2: NSPoint(x: cx - w / 2, y: cy - h * 0.12)
)
shield.close()

NSColor.white.setFill()
shield.fill()

// ── チェックマークをグラデーション色で ──
let check = NSBezierPath()
check.lineWidth = 52
check.lineCapStyle = .round
check.lineJoinStyle = .round
check.move(to: NSPoint(x: cx - 95, y: cy + 5))
check.line(to: NSPoint(x: cx - 25, y: cy - 70))
check.line(to: NSPoint(x: cx + 110, y: cy + 95))
topColor.setStroke()
check.stroke()

NSGraphicsContext.restoreGraphicsState()

guard let data = rep.representation(using: .png, properties: [:]) else {
    fatalError("PNG を生成できませんでした")
}
try! data.write(to: URL(fileURLWithPath: outputPath))
print("アイコンを書き出しました: \(outputPath)")
