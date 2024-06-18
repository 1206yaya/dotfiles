#!/bin/bash

VSCODE_EXTENSIONS_FILE=~/ghq/github.com/1206yaya/dotfiles/packages/vscode/vscode-extensions.txt

# ファイルから拡張機能の ID を読み込み、それぞれをインストール
while IFS= read -r extension_id
do
  code --install-extension "$extension_id"
done < "$VSCODE_EXTENSIONS_FILE"