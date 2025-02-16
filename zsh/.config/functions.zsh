#!/bin/bash

export GIT_CLONE_PATH="$HOME/ghq/github.com/1206yaya"
export DOTDIR="$GIT_CLONE_PATH/dotfiles"
export ZSH_CONFG_DIR="$DOTDIR/zsh/.config"

function makefile() {
    pathDir="$ZSH_CONFIG_DIR/makefile"
    # 初期の拡張子を設定
    ext="mk"

    # 引数に基づいてファイル名を構築し、ショートカットを考慮
    case "$1" in
    py | python | poetry)
        filename="poetry.$ext"
        ;;
    open | edit)
        subl $pathDir/
        return
        ;;
    *)
        # 特に設定がない場合は引数をそのままファイル名として扱う
        filename="${1}.$ext"
        if [ ! -f "$pathDir/$filename" ]; then
            # 拡張子が.htmlの場合を考慮
            ext="html"
            filename="${1}.$ext"
        fi
        ;;
    esac

    # ファイルの存在をチェックして、存在すればその内容を表示
    if [ -f "$pathDir/$filename" ]; then
        cat "$pathDir/$filename"
    else
        echo "No makefile found for $1"
    fi
}

chatutil() {
    if [ "$#" -ne 1 ]; then
        echo "使い方: chatutil <プロジェクトのルートディレクトリ>"
        return 1
    fi

    local PROJECT_ROOT=$1
    local SCRIPT_PATH="$HOME/.config/zsh/chatutil.py"
    local VENV_PATH="$DOTDIR/zsh/.config/.venv"

    # 仮想環境が存在するか確認
    if [ -d "$VENV_PATH" ]; then
        source "$VENV_PATH/bin/activate"
    else
        echo "エラー: 仮想環境が見つかりません ($VENV_PATH)"
        return 1
    fi

    python "$SCRIPT_PATH" "$PROJECT_ROOT"

    # 仮想環境を無効化
    deactivate
}

cs() {
    pathDir="$GIT_CLONE_PATH/cheet-sheet"

    # 引数に基づいてファイル名を構築し、ショートカットを考慮
    case "$1" in
    ios | iphone)
        filename="iphone.md"
        ;;
    kubectl | kl)
        filename="kubectl.md"
        ;;
    proto | protoc)
        filename="protoc.md"
        ;;
    py | python)
        filename="python.md"
        ;;
    gh | ghq)
        filename="ghq.md"
        ;;
    t | tmux)
        filename="tmux.md"
        ;;
    psql | pg)
        filename="postgresql.md"
        ;;
    gc | gcloud)
        filename="gcloud.md" # この行のファイル名は実際のファイル名に合わせてください
        ;;
    func | az)
        filename="func.md"
        ;;
    vscode | code)
        filename="vscode.md"
        ;;
    sgen | swagger-codegen)
        filename="swagger-codegen.md"
        ;;
    genc | openapi | openapi-generator)
        filename="openapi-generator.md"
        ;;
    docker | dc)
        filename="docker.md"
        ;;
    flutter)
        if [[ $2 == "pub" ]]; then
            filename="flutter-pub.sh"
        else
            filename="flutter.sh"
        fi
        ;;
    edit)
        cursor $pathDir/
        return
        ;;
    *)
        # 一致するファイル名を直接構築
        filename="${1}.md"
        if [ ! -f "$pathDir/$filename" ]; then
            filename="${1}.sh"
        fi
        ;;
    esac

    # ファイルの存在をチェック
    if [ -f "$pathDir/$filename" ]; then
        mdcat "$pathDir/$filename"
    else
        echo "No documentation found for $1"
    fi
}

gen() {

    GENDIR="$ZSH_CONFG_DIR/gen"

    if [ "$1" = "chatignore" ]; then
        sourceFile=$GENDIR"/.chatignore"
    elif [ "$1" = "csv" ]; then
        sourceFile=$GENDIR"/blank.csv"
    elif [ "$1" = "xlsx" ]; then
        sourceFile=$GENDIR"/blank.xlsx"
    else
        # それ以外の場合はエラー
        echo "第一引数には chatignore のいずれかを指定してください"

        return 1
    fi

    if [ -f "$filename" ]; then
        echo "すでに $filename が存在します"
    else
        cp $sourceFile ./
        echo "$filename を作成しました"
    fi

}
