#!/bin/sh
# macOS の設定をドットファイルにエクスポートするスクリプト

DOTDIR="${DOTDIR:-$(cd "$(dirname "$0")/.." && pwd)}"

echo "📌 Exporting macOS settings to dotfiles"

# キーボードショートカット
TMPFILE=$(mktemp)
defaults export com.apple.symbolichotkeys "$TMPFILE"
plutil -convert xml1 -o "$DOTDIR/macos/symbolichotkeys.plist" "$TMPFILE"
rm -f "$TMPFILE"
echo "[ OK ] Exported keyboard shortcuts to macos/symbolichotkeys.plist"
