#!/bin/zsh
syncdir() {
    # 現在のディレクトリの内容を出力
    ls -la
    # 引数の数をチェック
    if [[ $# -ne 2 ]]; then
        echo "Usage: syncdir <.sync file> <target directory>"
        return 1
    fi

    local sync_file=$1
    local target_directory=$2

    # .syncファイルの存在をチェック
    if [[ ! -f $sync_file ]]; then
        echo "Error: File $sync_file does not exist."
        return 1
    fi

    # .syncファイルのディレクトリを取得
    local sync_dir=$(dirname $sync_file)
    # .syncファイルの内容を配列として読み込む
    local directories=($(< $sync_file))
    echo "directories : $directories"
    for dir in $directories; do
        # 完全なソースパスを作成
        local full_source_path="${sync_dir}/$dir"
        # 完全なターゲットパスを作成
        local full_target_path="${target_directory}/$dir"
        # ファイルまたはディレクトリが存在するかチェック
        if [[ -d $full_source_path ]] || [[ -f $full_source_path ]]; then
            # ターゲットディレクトリが存在するか確認し、なければ作成
            local target_subdir=$(dirname $full_target_path)
            mkdir -p $target_subdir
            # ファイルまたはディレクトリをコピー
            cp -r $full_source_path $target_subdir
        else
            echo "Warning: $full_source_path does not exist and will be skipped."
        fi
    done
}

# syncdir() {
#     if [[ $# -ne 2 ]]; then
#         echo "Usage: syncdir <.sync file> <target directory>"
#         return 1
#     fi

#     local sync_file=$1
#     local target_directory=$2

#     if [[ ! -f $sync_file ]]; then
#         echo "Error: File $sync_file does not exist."
#         return 1
#     fi

#     local sync_dir=$(dirname $sync_file)
#     local directories=($(< $sync_file))

#     for dir in $directories; do
#         local full_source_path="$sync_dir/$dir"
#         if [[ -d $full_source_path ]] || [[ -f $full_source_path ]]; then
#             cp -r $full_source_path $target_directory/
#         else
#             echo "Warning: Directory or file $full_source_path does not exist and will be skipped."
#         fi
#     done
# }
# function syncdir() {
#     # 引数のチェック
#     if [[ $# -ne 2 ]]; then
#         echo "Usage: syncdir <.sync file> <target directory>"
#         return 1
#     fi

#     local sync_file=$1
#     local target_directory=$2

#     # .sync ファイルの存在チェック
#     if [[ ! -f $sync_file ]]; then
#         echo "Error: File $sync_file does not exist."
#         return 1
#     fi

#     # .sync ファイルからディレクトリ名を読み込む
#     local directories=($(< $sync_file))

#     # 各ディレクトリを同期
#     for dir in $directories; do
#         if [[ -d $dir ]]; then
#             cp -r $dir $target_directory/
#         else
#             echo "Warning: Directory $dir does not exist and will be skipped."
#         fi
#     done
# }

