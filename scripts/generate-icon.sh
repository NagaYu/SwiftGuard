#!/bin/bash
#
# SwiftGuard アプリアイコン (AppIcon.icns) を生成します。
#   ./scripts/generate-icon.sh
#
# Resources/draw_icon.swift で 1024px の元画像を描き、sips で各サイズを作り、
# iconutil で .icns 化して Resources/AppIcon.icns に出力します（build.sh が自動取り込み）。
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RES="$ROOT/Resources"
BASE="$RES/icon_1024.png"
ICONSET="$RES/AppIcon.iconset"
ICNS="$RES/AppIcon.icns"

log() { printf "\033[36m▶ %s\033[0m\n" "$1"; }

log "元画像 (1024px) を描画中..."
swift "$RES/draw_icon.swift" "$BASE"

log "iconset を生成中..."
rm -rf "$ICONSET"
mkdir -p "$ICONSET"

# (出力ファイル名, ピクセルサイズ) のペア
gen() { sips -z "$2" "$2" "$BASE" --out "$ICONSET/$1" >/dev/null; }
gen "icon_16x16.png"        16
gen "icon_16x16@2x.png"     32
gen "icon_32x32.png"        32
gen "icon_32x32@2x.png"     64
gen "icon_128x128.png"     128
gen "icon_128x128@2x.png"  256
gen "icon_256x256.png"     256
gen "icon_256x256@2x.png"  512
gen "icon_512x512.png"     512
gen "icon_512x512@2x.png" 1024

log ".icns に変換中..."
iconutil -c icns "$ICONSET" -o "$ICNS"

rm -rf "$ICONSET" "$BASE"
log "完了: Resources/AppIcon.icns（build.sh が自動で取り込みます）"
