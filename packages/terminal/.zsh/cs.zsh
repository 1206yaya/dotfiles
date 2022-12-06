#!/bin/bash


cs() {
    # pathDir=/mnt/c/Users/1206y/github/cheat.sheet/
    pathDir="/Users/zak/ghq/github.com/1206yaya/cheet-sheet"
    if [[ $@ == "aws-dynamodb" || $@ == "dynamo" || $@ == "dynamodb" ]]; then
        cat $pathDir/dynamodb.sh
    elif  [[ $@ == "py" || $@ == "python" ]]; then
        cat $pathDir/python.md
    elif  [[ $@ == "poetry" ]]; then
        cat $pathDir/poetry.sh
    elif  [[ $@ == "pandas" ]]; then
        cat $pathDir/pandas.md
    elif  [[ $@ == "npx" ]]; then
        cat $pathDir/npx.md
    elif  [[ $@ == "dart" ]]; then
        cat $pathDir/dart.sh
    elif  [[ $@ == "firebase" || $@ == "flutterfire" ]]; then
        cat $pathDir/firebase.md
    elif  [[ $@ == "pyenv" ]]; then
        cat $pathDir/pyenv.sh
    elif  [[ $1 == "docker" || $1 == "dc" ]]; then
        if [[ $2 == "fix" ]]; then
            cat $pathDir/docker.fix.sh
        else
            cat $pathDir/docker.sh
        fi 
    elif  [[ $1 == "flutter" ]]; then
        if [[ $2 == "pub" ]]; then
            cat $pathDir/flutter-pub.sh
        else
            cat $pathDir/flutter.sh
        fi 
    elif  [[ $1 == "pub" ]]; then
        cat $pathDir/flutter-pub.sh

    elif  [[ $1 == "sls" || $1 == "serverless" ]]; then
        if [[ $2 == "fix" ]]; then
            cat $pathDir/sls.fix.sh
        else
            cat $pathDir/sls.sh
        fi 
    elif  [[ $@ == "copilot" || $@ == "copi" ]]; then
        cat $pathDir/copilot.sh
    elif  [[ $@ == "sam" ]]; then
        cat $pathDir/sam.sh
    elif  [[ $@ == "makefile" || $@ == "make" ]]; then
        cat $pathDir/makefile.sh
    elif  [[ $@ == "bash" || $@ == "sh" ]]; then
        cat $pathDir/bash.sh
    elif  [[ $@ == "git" ]]; then
        cat $pathDir/git.sh
    elif  [[ $@ == "ghq" ]]; then
        cat $pathDir/ghq.sh
    elif  [[ $@ == "fvm" ]]; then
        cat $pathDir/fvm.sh
    elif  [[ $@ == "sql" ]]; then
        cat $pathDir/sql.sh
    elif  [[ $@ == "react" ]]; then
        cat $pathDir/react.sh
    elif  [[ $@ == "ts" || $@ == "typescript" ]]; then
        cat $pathDir/typescript.sh
    elif  [[ $@ == "open" || $@ == "edit" ]]; then
        code $pathDir/

    else
        cat <<- EOF
Nothing $@ 
EOF
    fi
}