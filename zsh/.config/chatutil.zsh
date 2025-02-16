#!/bin/zsh
# 既存の chatutil エイリアスを解除
unalias chatutil 2>/dev/null
chatutil() {
    if [ "$#" -ne 1 ]; then
        echo "使い方: chatutil <プロジェクトのルートディレクトリ>"
        return 1
    fi

    local PROJECT_ROOT=$1
    local SCRIPT_PATH=".config/zsh/chatutil.py"
    python "$SCRIPT_PATH" "$PROJECT_ROOT"
}