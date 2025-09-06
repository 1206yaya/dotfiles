#!/bin/bash
alias gm='git commit -m "$@"'
alias gam="git add . ; git commit -m "$@""
alias wip="git add . ; git commit -m "wip""
alias gconf='cat $(git rev-parse --show-toplevel)/.git/config'
alias gtags="git tag -l"

# Git
# >>> ⭐️ ⭐️ workflow of repository create on github ⭐️ ⭐️
# gam 'first commit'
# ggen
function restoreapi() {
  cd ${HOME}/ghq/github.com/hrbrain/hrbrain
  git restore apps/persia/app/handlers/http/oapi/api.gen.go \
    apps/persia/app/handlers/http/oapi/spec.gen.go \
    apps/persia/front/src/adapters/gen/api.ts
}
function ggen() {
  # 引数がセットされていればそれをレポジトリ名に、そうでなければカレントディレクトリ名
  REPO_NAME=
  if [[ $# -eq 0 ]]; then
    CURERNT_DIR=$(printf '%s\n' "${PWD##*/}")
    REPO_NAME=$CURERNT_DIR
  else
    REPO_NAME=$@
  fi

  if [[ -e README.md ]]; then
    touch README.md
  fi

  if [[ ! -d .git ]]; then
    git init
  fi

  git branch -M main
  git add .
  git commit -m 'initial commit'
  # git remote add origin https://github.com/1206yaya/${REPO_NAME}.git
  git remote add origin git@github.com:1206yaya/${REPO_NAME}.git
  gh repo create --private $REPO_NAME

  git push --set-upstream origin main
}

function gi() { curl -sL https://www.gitignore.io/api/$@; }

function gb {
  git checkout $@
}

function gnb {
  git checkout -b $@
}
function gtam() {
  if [[ -z $1 ]]; then
    echo "タグ名を第１引数に指定してください"
    return 1
  fi
  if [[ -z $2 ]]; then
    echo "タグコメントを第２引数に指定してください"
    return 1
  fi
  git tag -a $1 -m $2
  git push origin $1
}
function gdeltag() {
  if [[ -z $1 ]]; then
    echo "タグ名を第１引数に指定してください"
    return 1
  fi
  git tag -d $1
  git push --delete origin $1
}
