#!/bin/bash
#
# SwiftGuard 配布用ビルドスクリプト
# ------------------------------------------------------------
# CLI バイナリ・SwiftGuard.app・SwiftGuard.dmg を一発で生成します。
#
# 使い方:
#   ./scripts/build.sh            # すべて（CLI + .app + .dmg）をビルド
#   ./scripts/build.sh app        # .app のみ
#   ./scripts/build.sh dmg        # .app + .dmg
#   ./scripts/build.sh cli        # CLI のみ
#
# 成果物は dist/ 以下に出力されます。
#
set -euo pipefail

# ── 設定 ───────────────────────────────────────────────
APP_NAME="SwiftGuard"
APP_EXECUTABLE="SwiftGuardApp"      # SPM の executable product 名
CLI_EXECUTABLE="swiftguard"
BUNDLE_ID="com.swiftguard.app"
VERSION="0.2.0"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST="$ROOT/dist"
BUILD_CONFIG="release"

# Xcode が必要（FoundationModels のマクロプラグインのため）。
# Command Line Tools だけがアクティブな場合は Xcode を指す。
if ! xcrun --find xctest >/dev/null 2>&1; then
    if [ -d "/Applications/Xcode.app" ]; then
        export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
    fi
fi

ARCH_FLAGS="--arch arm64 --arch x86_64"   # ユニバーサルバイナリ

log() { printf "\033[36m▶ %s\033[0m\n" "$1"; }

# ── CLI ───────────────────────────────────────────────
build_cli() {
    log "CLI (${CLI_EXECUTABLE}) をビルド中..."
    swift build -c "$BUILD_CONFIG" $ARCH_FLAGS --product "$CLI_EXECUTABLE"
    mkdir -p "$DIST"
    local bin
    bin="$(swift build -c "$BUILD_CONFIG" $ARCH_FLAGS --show-bin-path)/$CLI_EXECUTABLE"
    cp "$bin" "$DIST/$CLI_EXECUTABLE"
    log "CLI 出力: dist/$CLI_EXECUTABLE"
}

# ── .app バンドル ──────────────────────────────────────
build_app() {
    log "GUI (${APP_NAME}.app) をビルド中..."
    swift build -c "$BUILD_CONFIG" $ARCH_FLAGS --product "$APP_EXECUTABLE"

    local bin_dir
    bin_dir="$(swift build -c "$BUILD_CONFIG" $ARCH_FLAGS --show-bin-path)"

    local app="$DIST/$APP_NAME.app"
    rm -rf "$app"
    mkdir -p "$app/Contents/MacOS"
    mkdir -p "$app/Contents/Resources"

    # 実行ファイルを配置（アプリ名に合わせてリネーム）。
    cp "$bin_dir/$APP_EXECUTABLE" "$app/Contents/MacOS/$APP_NAME"
    chmod +x "$app/Contents/MacOS/$APP_NAME"

    # Info.plist を生成。
    cat > "$app/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>            <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>     <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>      <string>$BUNDLE_ID</string>
    <key>CFBundleVersion</key>         <string>$VERSION</string>
    <key>CFBundleShortVersionString</key><string>$VERSION</string>
    <key>CFBundleExecutable</key>      <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>     <string>APPL</string>
    <key>LSMinimumSystemVersion</key>  <string>26.0</string>
    <key>NSHighResolutionCapable</key> <true/>
    <key>LSApplicationCategoryType</key><string>public.app-category.developer-tools</string>
</dict>
</plist>
PLIST

    # アイコンがあれば取り込む（任意）。
    if [ -f "$ROOT/Resources/AppIcon.icns" ]; then
        cp "$ROOT/Resources/AppIcon.icns" "$app/Contents/Resources/AppIcon.icns"
        /usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string AppIcon" "$app/Contents/Info.plist" 2>/dev/null || true
    fi

    # アドホック署名（Gatekeeper の起動を通しやすくする。配布時は Developer ID 署名を推奨）。
    codesign --force --deep --sign - "$app" 2>/dev/null || \
        log "（警告）codesign に失敗しました。未署名のまま続行します。"

    log ".app 出力: dist/$APP_NAME.app"
}

# ── .dmg ──────────────────────────────────────────────
build_dmg() {
    build_app
    log "${APP_NAME}.dmg を作成中..."

    local dmg="$DIST/$APP_NAME-$VERSION.dmg"
    local staging="$DIST/dmg-staging"
    rm -rf "$staging" "$dmg"
    mkdir -p "$staging"
    cp -R "$DIST/$APP_NAME.app" "$staging/"
    ln -s /Applications "$staging/Applications"   # ドラッグ＆ドロップ用ショートカット

    hdiutil create \
        -volname "$APP_NAME" \
        -srcfolder "$staging" \
        -ov -format UDZO \
        "$dmg" >/dev/null

    rm -rf "$staging"
    log ".dmg 出力: $dmg"
}

# ── エントリポイント ───────────────────────────────────
mkdir -p "$DIST"
case "${1:-all}" in
    cli) build_cli ;;
    app) build_app ;;
    dmg) build_dmg ;;
    all) build_cli; build_dmg ;;
    *)   echo "使い方: $0 [all|cli|app|dmg]"; exit 1 ;;
esac

log "完了 🎉  成果物は dist/ にあります。"
