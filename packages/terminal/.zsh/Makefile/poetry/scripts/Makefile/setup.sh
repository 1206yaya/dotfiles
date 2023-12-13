#!/bin/bash
PROJ_DIR=`pwd`

RESOURCE_DIR=~/ghq/github.com/1206yaya/dotfiles/packages/terminal/.zsh/Makefile/poetry
if [ ! -f ./requirements.txt ]; then 
  cp ${RESOURCE_DIR}/requirements.txt ./requirements.txt; 
fi
if [ ! -f ./requirements-dev.txt ]; then 
  cp ${RESOURCE_DIR}/requirements-dev.txt ./requirements-dev.txt; 
fi

# .vscode ディレクトリが存在するか確認し、存在しなければコピーする
if [ ! -d ./.vscode ]; then 
  if [ -d ${RESOURCE_DIR}/.vscode ]; then
    cp -r ${RESOURCE_DIR}/.vscode ./; 
  else
    echo "Resource directory .vscode does not exist."
  fi
fi