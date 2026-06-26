#!/bin/sh
#
# SwiftGuard の pre-commit フックをこのリポジトリにインストールします。
#
set -eu

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || true)
if [ -z "$ROOT" ]; then
    echo "❌ Git リポジトリ内で実行してください。"
    exit 1
fi

SRC="$ROOT/scripts/pre-commit"
DST="$ROOT/.git/hooks/pre-commit"

if [ ! -f "$SRC" ]; then
    echo "❌ $SRC が見つかりません。"
    exit 1
fi

cp "$SRC" "$DST"
chmod +x "$DST"
echo "✅ pre-commit フックをインストールしました: $DST"
echo "   無効化: SWIFTGUARD_SKIP=1 git commit ... / 1回だけ回避: git commit --no-verify"
