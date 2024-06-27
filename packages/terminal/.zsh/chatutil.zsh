

# このスクリプトは、ChatGPT用のツールです
# ローカルプロジェクトのソースコードに関して質問するときに、プロジェクト内の関連するファイルをChatGPTが理解しやすい形で出力するためのツールです
# このスクリプトは、指定されたディレクトリ内のファイルを再帰的に検索します。

# 出力形式は、以下の通りです:
# 1. プロジェクトのルートディレクトリからの相対パス
# 2. ファイルの内容を```のようにバッククオートで囲んで出力する(コメント行は含めない)

# ルートディレクトリに .chatignore ファイルが存在する場合、そのファイルに記載されているファイルは無視されます
# .chatignore は .gitignore と同じ形式で記述します

# Usage: cu <プロジェクトのルートディレクトリ>
#!/bin/zsh

chatutil() {
  if [ "$#" -ne 1 ]; then
      echo "使い方: cu <プロジェクトのルートディレクトリ>"
      return 1
  fi

  # プロジェクトのルートディレクトリ
  local PROJECT_ROOT=$1

  # '.' または './' の場合にカレントディレクトリを処理
  if [[ "$PROJECT_ROOT" == "." || "$PROJECT_ROOT" == "./" ]]; then
    PROJECT_ROOT=$PWD
  fi


  # ディレクトリが存在するかどうかをチェック
  if [ ! -d "$PROJECT_ROOT" ]; then
      echo "エラー: 指定されたディレクトリが存在しません"
      return 1
  fi

  # .chatignore ファイルの存在をチェック
  local CHATIGNORE_FILE="$PROJECT_ROOT/.chatignore"
  local IGNORE_PATTERNS=()
  if [ -f "$CHATIGNORE_FILE" ]; then
      while IFS= read -r line; do
          # コメント行や空行を無視
          if [[ ! "$line" =~ ^\s*# ]] && [[ -n "$line" ]]; then
              IGNORE_PATTERNS+=("$line")
          fi
      done < "$CHATIGNORE_FILE"
  fi

  # 無視パターンに一致するかを確認する関数
  should_ignore() {
      local path=$1
      for pattern in "${IGNORE_PATTERNS[@]}"; do
          if [[ "$path" == $pattern ]] || [[ "$path" =~ $pattern ]]; then
              return 0
          fi
      done
      return 1
  }

  # 指定されたディレクトリ内のファイルを再帰的に検索
  find "$PROJECT_ROOT" -type f | while read -r file; do
      # 相対パスの取得
      local relative_path=${file#$PROJECT_ROOT/}

      # 無視パターンに一致する場合はスキップ
      if should_ignore "$relative_path"; then
          continue
      fi

      # ファイルの内容を読み込み、コメント行を除く
      local file_contents=$(grep -v '^\s*#' "$file")

      # 出力形式に整形して表示
      echo "$relative_path"
      echo '```'
      echo "$file_contents"
      echo '```'
      echo
  done
}
