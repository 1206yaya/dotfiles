#!/bin/zsh
#
# Tilt Worktree更新コマンド
# どこからでも実行可能なZsh関数として定義

update-tilt-worktree() {
    # hrbrainリポジトリのルートパス
    local HRBRAIN_ROOT="/Users/Komatsu.Aya/ghq/github.com/hrbrain/hrbrain"
    local SCRIPT_PATH="$HRBRAIN_ROOT/scripts/update-tilt-worktree.sh"

    # スクリプトの存在確認
    if [[ ! -f "$SCRIPT_PATH" ]]; then
        echo "エラー: スクリプトが見つかりません: $SCRIPT_PATH" >&2
        return 1
    fi

    # 元のディレクトリを保存
    local original_dir="$PWD"

    # hrbrainリポジトリに移動してスクリプトを実行
    cd "$HRBRAIN_ROOT" || {
        echo "エラー: ディレクトリに移動できません: $HRBRAIN_ROOT" >&2
        return 1
    }

    # スクリプトを実行（引数をそのまま渡す）
    "$SCRIPT_PATH" "$@"
    local exit_code=$?

    # 元のディレクトリに戻る
    cd "$original_dir" || {
        echo "警告: 元のディレクトリに戻れませんでした: $original_dir" >&2
    }

    return $exit_code
}

# エイリアスも設定（短縮形）
alias utw='update-tilt-worktree'
