#!/bin/bash


cs() {
    # pathDir=/mnt/c/Users/1206y/github/cheat.sheet/
    pathDir="/Users/zak/ghq/github.com/1206yaya/cheet-sheet"
    if [[ $@ == "aws-dynamodb" || $@ == "dynamo" || $@ == "dynamodb" ]]; then
        mdcat $pathDir/dynamodb.sh
    elif  [[ $@ == "py" || $@ == "python" ]]; then
        mdcat $pathDir/python.md
    elif  [[ $@ == "psql" || $@ == "pg" ]]; then
        mdcat $pathDir/postgresql.md
    elif  [[ $@ == "asdf" ]]; then
        mdcat $pathDir/asdf.md
    elif  [[ $@ == "jupyter" ]]; then
        mdcat $pathDir/jupyter.md
    elif  [[ $@ == "gc" || $@ == "gcloud" ]]; then
        mdcat $pathDir/postgresql.md
    elif  [[ $@ == "func" || $@ == "az" ]]; then
        mdcat $pathDir/func.md
    elif  [[ $@ == "poetry" ]]; then
        mdcat $pathDir/poetry.md
    elif  [[ $@ == "pandas" ]]; then
        mdcat $pathDir/pandas.md
    elif  [[ $@ == "npx" ]]; then
        mdcat $pathDir/npx.md
    elif  [[ $@ == "dart" ]]; then
        mdcat $pathDir/dart.sh
    elif  [[ $@ == "firebase" || $@ == "flutterfire" ]]; then
        mdcat $pathDir/firebase.md
    elif  [[ $@ == "pyenv" ]]; then
        mdcat $pathDir/pyenv.sh
    elif  [[ $1 == "docker" || $1 == "dc" ]]; then
        if [[ $2 == "fix" ]]; then
            mdcat $pathDir/docker.fix.sh
        else
            mdcat $pathDir/docker.sh
        fi 
    elif  [[ $1 == "flutter" ]]; then
        if [[ $2 == "pub" ]]; then
            mdcat $pathDir/flutter-pub.sh
        else
            mdcat $pathDir/flutter.sh
        fi 
    elif  [[ $1 == "pub" ]]; then
        mdcat $pathDir/flutter-pub.sh

    elif  [[ $1 == "sls" || $1 == "serverless" ]]; then
        if [[ $2 == "fix" ]]; then
            mdcat $pathDir/sls.fix.sh
        else
            mdcat $pathDir/sls.sh
        fi 
    elif  [[ $@ == "copilot" || $@ == "copi" ]]; then
        mdcat $pathDir/copilot.sh
    elif  [[ $@ == "sam" ]]; then
        mdcat $pathDir/sam.sh
    elif  [[ $@ == "makefile" || $@ == "make" ]]; then
        mdcat $pathDir/makefile.md
    elif  [[ $@ == "bash" || $@ == "sh" ]]; then
        mdcat $pathDir/bash.md
    elif  [[ $@ == "git" ]]; then
        mdcat $pathDir/git.sh
    elif  [[ $@ == "ghq" ]]; then
        mdcat $pathDir/ghq.sh
    elif  [[ $@ == "fvm" ]]; then
        mdcat $pathDir/fvm.sh
    elif  [[ $@ == "sql" ]]; then
        mdcat $pathDir/sql.sh
    elif  [[ $@ == "react" ]]; then
        mdcat $pathDir/react.sh
    elif  [[ $@ == "ts" || $@ == "typescript" ]]; then
        mdcat $pathDir/typescript.sh
    elif  [[ $@ == "open" || $@ == "edit" ]]; then
        code $pathDir/

    else
        mdcat <<- EOF
Nothing $@ 
EOF
    fi
}