#!/bin/zsh

genfiles() {
    if [ "$#" -ne 1 ]; then
        echo "使い方: genfiles <生成するファイル群の情報が記載されたファイルパス>"
        return 1
    fi

    local TARGET_PATH=$1
    local SCRIPT_PATH="/Users/zak/ghq/github.com/1206yaya/dotfiles/packages/terminal/.zsh/genfiles.py"
    python "$SCRIPT_PATH" "$TARGET_PATH"
}