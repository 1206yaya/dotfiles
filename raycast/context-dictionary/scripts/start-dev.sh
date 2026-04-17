#!/bin/bash
# launchd から呼ばれるラッパー。mise 経由で正しい Node を使う
export PATH="$HOME/.local/share/mise/shims:$PATH"
cd "$(dirname "$0")/.." || exit 1
exec npm run dev
