#!/usr/bin/env bash
set -euo pipefail
export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
IFS=$'\n\t'

# PROJECT: alacritty_transparency
config_file="$HOME/.config/alacritty/alacritty.toml"
real_config_file=$(realpath "$config_file")  # シンボリックリンクの実体を取得

# ファイルの存在チェック
if [[ ! -f "$real_config_file" ]]; then
    echo "Error: Config file not found at $real_config_file"
    exit 1
fi

# Toggle Alacritty opacity
current_opacity=$(grep 'opacity = ' "$real_config_file" | cut -d'=' -f2 | tr -d ' ')

# 一時ファイルを作成して sed の処理を行う
tmp_file=$(mktemp)
case "$current_opacity" in
0.9)
    sed 's/opacity = .*/opacity = 1.0/' "$real_config_file" > "$tmp_file"
    mv "$tmp_file" "$real_config_file"

    # When going opaque, set dark backgrounds
    tmux set-window-option -g window-active-style 'bg=#000000'
    tmux set-window-option -g window-style 'bg=#0B0B0B'
    ;;
1.0 | *)
    sed 's/opacity = .*/opacity = 0.9/' "$real_config_file" > "$tmp_file"
    mv "$tmp_file" "$real_config_file"

    # When going transparent, set default backgrounds
    tmux set-window-option -g window-active-style 'bg=default'
    tmux set-window-option -g window-style 'bg=default'
    ;;
esac
