#!/bin/bash

gom() {
  # gom <PackageName>
  # カレントディレクトリに PackageName ディレクトリを作成
  # 絶対パスが /Users/zak/ghq/github.com/1206yaya/.... のようになっているので `/Users/zak/ghq/` を削除したパスを元に go mod init を実行する
  if [ -z "$1" ]; then
    echo "Usage: gom <PackageName>"
    return 1
  fi

  PACKAGE_NAME=$1
  CURRENT_PATH=$(pwd)

  # パスを作成
  TARGET_PATH="$CURRENT_PATH/$PACKAGE_NAME"

  # ディレクトリが既に存在する場合の処理
  if [ -f "$TARGET_PATH/go.mod" ]; then
    echo "Error: go.mod already exists in $TARGET_PATH."
    return 1
  fi
  mkdir -p "$TARGET_PATH"

  # go mod init のためのモジュール名を作成
  RELATIVE_PATH=${TARGET_PATH#/Users/zak/ghq/} # BASE_PATH 部分を削除

  # ディレクトリへ移動して go mod init を実行
  cd "$TARGET_PATH" || return 1
  go mod init "$RELATIVE_PATH"

  if [ -f "$TARGET_PATH/main.go" ]; then
    echo "Initialized Go module in $TARGET_PATH with module name $RELATIVE_PATH"
    return 0
  fi

  # main.go ファイルを作成
  cat <<EOF >"$TARGET_PATH/main.go"
package main

import "fmt"

func main() {
	fmt.Println("Hello")
}
EOF

  echo "Initialized Go module in $TARGET_PATH with module name $RELATIVE_PATH"
  echo "Created main.go in $TARGET_PATH"

  cd ../
}
