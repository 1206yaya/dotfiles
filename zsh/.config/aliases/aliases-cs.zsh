cs() {
    pathDir="$HOME/ghq/github.com/1206yaya/cheet-sheet"

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
        filename="gcloud.md"
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
        code $pathDir/
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
