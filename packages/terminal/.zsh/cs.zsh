#!/bin/bash


cs() {
    pathDir="/Users/zak/ghq/github.com/1206yaya/cheet-sheet"

    # 引数に基づいてファイル名を構築し、ショートカットを考慮
    case "$1" in
        py|python)
            filename="python.md"
            ;;
        edit)
            code $pathDir/
            return 
            ;;
        psql|pg)
            filename="postgresql.md"
            ;;
        gc|gcloud)
            filename="gcloud.md" # この行のファイル名は実際のファイル名に合わせてください
            ;;
        func|az)
            filename="func.md"
            ;;
        vscode|code)
            filename="vscode.md"
            ;;
        sgen|swagger-codegen)
            filename="swagger-codegen.md"
            ;;
        genc|openapi|openapi-generator)
            filename="openapi-generator.md"
            ;;
        docker|dc)
            if [[ $2 == "fix" ]]; then
                filename="docker.fix.sh"
            else
                filename="docker.sh"
            fi
            ;;
        flutter)
            if [[ $2 == "pub" ]]; then
                filename="flutter-pub.sh"
            else
                filename="flutter.sh"
            fi
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



# cs1() {
#     # pathDir=/mnt/c/Users/1206y/github/cheat.sheet/
#     pathDir="/Users/zak/ghq/github.com/1206yaya/cheet-sheet"
#     if [[ $@ == "aws-dynamodb" || $@ == "dynamo" || $@ == "dynamodb" ]]; then
#         mdcat $pathDir/dynamodb.sh
#     elif  [[ $@ == "py" || $@ == "python" ]]; then
#         mdcat $pathDir/python.md
#     elif  [[ $@ == "psql" || $@ == "pg" ]]; then
#         mdcat $pathDir/postgresql.md
#     elif  [[ $@ == "asdf" ]]; then
#         mdcat $pathDir/asdf.md
#     elif  [[ $@ == "npm" ]]; then
#         mdcat $pathDir/npm.md
#     elif  [[ $@ == "jupyter" ]]; then
#         mdcat $pathDir/jupyter.md
#     elif  [[ $@ == "gc" || $@ == "gcloud" ]]; then
#         mdcat $pathDir/postgresql.md
#     elif  [[ $@ == "func" || $@ == "az" ]]; then
#         mdcat $pathDir/func.md
#     elif  [[ $@ == "poetry" ]]; then
#         mdcat $pathDir/poetry.md
#     elif  [[ $@ == "pandas" ]]; then
#         mdcat $pathDir/pandas.md
#     elif  [[ $@ == "pydoc" ]]; then
#         mdcat $pathDir/pydoc.md
#     elif  [[ $@ == "vscode" || $@ == "code" ]]; then
#         mdcat $pathDir/vscode.md
#     elif  [[ $@ == "tree" ]]; then
#         mdcat $pathDir/tree.md
#     elif  [[ $@ == "svn" ]]; then
#         mdcat $pathDir/svn.md
#     elif  [[ $@ == "npx" ]]; then
#         mdcat $pathDir/npx.md
#     elif  [[ $@ == "swagger-codegen" ||  $@ == "sgen" ]]; then
#         mdcat $pathDir/swagger-codegen.md
#     elif  [[ $@ == "openapi-generator" ||  $@ == "genc" ||  $@ == "openapi" ]]; then
#         mdcat $pathDir/openapi-generator.md
#     elif  [[ $@ == "dart" ]]; then
#         mdcat $pathDir/dart.sh
#     elif  [[ $@ == "firebase" || $@ == "flutterfire" ]]; then
#         mdcat $pathDir/firebase.md
#     elif  [[ $@ == "pyenv" ]]; then
#         mdcat $pathDir/pyenv.sh
#     elif  [[ $1 == "docker" || $1 == "dc" ]]; then
#         if [[ $2 == "fix" ]]; then
#             mdcat $pathDir/docker.fix.sh
#         else
#             mdcat $pathDir/docker.sh
#         fi 
#     elif  [[ $1 == "flutter" ]]; then
#         if [[ $2 == "pub" ]]; then
#             mdcat $pathDir/flutter-pub.sh
#         else
#             mdcat $pathDir/flutter.sh
#         fi 
#     elif  [[ $1 == "pub" ]]; then
#         mdcat $pathDir/flutter-pub.sh

#     elif  [[ $1 == "sls" || $1 == "serverless" ]]; then
#         if [[ $2 == "fix" ]]; then
#             mdcat $pathDir/sls.fix.sh
#         else
#             mdcat $pathDir/sls.sh
#         fi 
#     elif  [[ $@ == "copilot" || $@ == "copi" ]]; then
#         mdcat $pathDir/copilot.sh
#     elif  [[ $@ == "sam" ]]; then
#         mdcat $pathDir/sam.sh
#     elif  [[ $@ == "makefile" || $@ == "make" ]]; then
#         mdcat $pathDir/makefile.md
#     elif  [[ $@ == "bash" || $@ == "sh" ]]; then
#         mdcat $pathDir/bash.md
#     elif  [[ $@ == "git" ]]; then
#         mdcat $pathDir/git.md
#     elif  [[ $@ == "ghq" ]]; then
#         mdcat $pathDir/ghq.sh
#     elif  [[ $@ == "fvm" ]]; then
#         mdcat $pathDir/fvm.sh
#     elif  [[ $@ == "sql" ]]; then
#         mdcat $pathDir/sql.sh
#     elif  [[ $@ == "react" ]]; then
#         mdcat $pathDir/react.sh
#     elif  [[ $@ == "ts" || $@ == "typescript" ]]; then
#         mdcat $pathDir/typescript.sh
#     elif  [[ $@ == "open" || $@ == "edit" ]]; then
#         code $pathDir/

#     else
#         mdcat <<- EOF
# Nothing $@ 
# EOF
#     fi
# }