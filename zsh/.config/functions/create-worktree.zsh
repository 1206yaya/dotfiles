#!/bin/zsh
#
# Git Worktree作成コマンド
# どこからでも実行可能なZsh関数として定義

create-worktree() {
    # hrbrainリポジトリのルートパス
    local HRBRAIN_ROOT="/Users/Komatsu.Aya/ghq/github.com/hrbrain/hrbrain"
    local SCRIPT_PATH="$HRBRAIN_ROOT/scripts/create-worktree.sh"

    # スクリプトの存在確認
    if [[ ! -f "$SCRIPT_PATH" ]]; then
        echo "エラー: スクリプトが見つかりません: $SCRIPT_PATH" >&2
        return 1
    fi

    # 引数の数をチェック
    if [[ $# -lt 2 ]]; then
        echo "使用法: create-worktree <サービス名> <ブランチ名>" >&2
        echo "例: create-worktree persia persia-feat1" >&2
        return 1
    fi

    # 元のディレクトリを保存
    local original_dir="$PWD"

    # hrbrainリポジトリに移動してスクリプトを実行
    cd "$HRBRAIN_ROOT" || {
        echo "エラー: ディレクトリに移動できません: $HRBRAIN_ROOT" >&2
        return 1
    }

    # HRBRAIN_DIR環境変数を設定してスクリプトを実行
    env HRBRAIN_DIR="$HRBRAIN_ROOT" "$SCRIPT_PATH" "$@"
    local exit_code=$?

    # スクリプトが成功した場合、ワークツリーに移動してVS Codeで開く
    if [[ $exit_code -eq 0 ]]; then
        local branch_name="$2"
        local worktree_path="$HRBRAIN_ROOT/.worktree/$branch_name"
        
        if [[ -d "$worktree_path" ]]; then
            cd "$worktree_path" || {
                echo "警告: ワークツリーディレクトリに移動できませんでした: $worktree_path" >&2
                cd "$original_dir"
                return 1
            }
            
            # VS Codeで開く
            code "$worktree_path"
            
            echo "✓ ワークツリーに移動してVS Codeで開きました: $worktree_path"
        else
            echo "警告: ワークツリーが見つかりません: $worktree_path" >&2
            cd "$original_dir"
            return 1
        fi
    else
        # 失敗した場合は元のディレクトリに戻る
        cd "$original_dir" || {
            echo "警告: 元のディレクトリに戻れませんでした: $original_dir" >&2
        }
    fi

    return $exit_code
}

# エイリアスも設定（短縮形）
alias cw='create-worktree'