# gen() {
#   # 連想配列の定義
#   typeset -A FILE_TYPES
#   FILE_TYPES=(
#     "go_router" "dart"
#     "pubspec" "yaml"
#   )

#   FILE_NAME=$1
#   EXTENSION="${FILE_TYPES[$FILE_NAME]}"

#   # Step1. FILE_NAMEが FILE_TYPES に含まれていない場合、キーを表示して終了
#   if [[ -z "$EXTENSION" ]]; then
#     echo "第1引数には、${(k)FILE_TYPES[@]} のいずれかを指定してください"
#     return 1
#   fi

#   MAKEFILE_PATH="$HOME/ghq/github.com/1206yaya/dotfiles/packages/terminal/.zsh/gen"
#   cat ${MAKEFILE_PATH}/${FILE_NAME}.${EXTENSION}
# }
