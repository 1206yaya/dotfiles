#!/bin/bash

ci() {
    local base_path="/Users/zak/ghq/github.com/1206yaya/dotfiles/packages/terminal/.zsh/chatignore"
    local file_name="$1.txt"
    local full_path="$base_path/$file_name"

    if [ -f "$full_path" ]; then
        cat "$full_path"
    else
        echo "Error: File $file_name not found in $base_path"
        return 1
    fi
}