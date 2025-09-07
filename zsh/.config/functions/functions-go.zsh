#!/bin/bash

#### 概要
#指定した名前で新しいGoモジュールを簡単に作成するための便利コマンドです。
#### 使用方法
#```shell
#gom <PackageName>
#```
#### 機能の詳細
#* 現在のディレクトリ内に、指定した `<PackageName>` という名前の新しいディレクトリを作成します。
#* この新しいディレクトリ内で `go mod init` を自動的に実行し、適切なモジュール名を設定します。
#* モジュール名はディレクトリの絶対パスから特定のベースパス（`/Users/zak/ghq/`）を削除したパスとして設定されます。
#* 新しいモジュール内には、自動でサンプルコード入りの `main.go` ファイルを作成します。
#### 例
#次のコマンドを実行した場合：
#```shell
#gom exampleModule
#```
#* 現在の場所に `exampleModule` というディレクトリが作成されます。
#* その中で `go mod init github.com/1206yaya/.../exampleModule` のような形式でモジュールが初期化されます。
#* 自動的に `main.go` ファイルが作成され、簡単なサンプルプログラムが書き込まれます。
#### 注意事項
#* モジュールを作成したい名前を必ず引数として指定してください。
#* 対象のディレクトリに既に `go.mod` ファイルが存在している場合はエラーになります。
#このコマンドを利用すると、Goプロジェクトの作成作業を簡単・迅速に進めることができます。
#!/bin/bash
#!/bin/bash

gom() {
  if [ -z "$1" ]; then
    echo "Usage: gom <PackageName>"
    return 1
  fi

  PACKAGE_NAME=$1
  CURRENT_PATH=$(pwd)
  TARGET_PATH="$CURRENT_PATH/$PACKAGE_NAME"

  if [ -d "$TARGET_PATH" ]; then
    echo "Directory $TARGET_PATH already exists. Entering..."
    cd "$TARGET_PATH" || return 1
    if [ -f "go.mod" ]; then
      echo "go.mod already exists in $TARGET_PATH. Running go mod tidy..."
      go mod tidy
    else
      echo "Initializing go module..."
      go mod init "$PACKAGE_NAME"
      go mod tidy
    fi
    return 0
  fi

  mkdir -p "$TARGET_PATH"
  cd "$TARGET_PATH" || return 1
  go mod init "$PACKAGE_NAME"

  cat <<EOF >"main.go"
package main

import "fmt"

func main() {
	fmt.Println("Hello")
}
EOF

  go mod tidy

  echo "Initialized Go module in $TARGET_PATH with module name $PACKAGE_NAME"
  echo "Created main.go in $TARGET_PATH"
}
