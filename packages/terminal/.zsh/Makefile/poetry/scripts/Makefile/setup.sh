#!/bin/bash
PROJ_DIR=`pwd`

RESOURCE_DIR=~/ghq/github.com/1206yaya/dotfiles/packages/terminal/.zsh/Makefile/poetry
# rsyncを使用して、RESOURCE_DIRから現在のディレクトリに、まだ存在しないファイルとディレクトリをコピーする
rsync -av --ignore-existing ${RESOURCE_DIR}/ .
