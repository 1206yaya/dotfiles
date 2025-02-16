
alias q="exit"
alias qq="osascript -e 'tell application \"iTerm2\" to quit'"
alias o="open ."
alias pr="gh pr view --web"
# Network
alias localip="ifconfig en0 | grep 'inet ' | awk '{ print $2 }'"

alias ls="ls -lt  "$@""
alias pb="pbcopy"
alias mkdir='mkdir -p' # 深いネストのディレクトリも作成可能
function touchp() { if [[ "$1" == */* ]]; then if [ ! -d "${1%/*}/" ]; then mkdir -p "${1%/*}/"; fi; fi; touch "$1" } # ディレクトリがない場合は作成してファイルを作成
alias genb="git switch -c "$@""
alias ghclose="gh issue close "$@""
alias ghcreate='gh issue create --title "$@" --body "Issue description"'
alias hub='gh browse'
alias lc="pbcopy | chatutil "$@""
alias lsgrep="ls -ltr | grep "$@""
alias py="pbcopy"

alias cdd="builtin cd"
# ランダムなパスワードを生成する
# 引数にパスワードの長さを指定できる
# デフォルトは 10
function genpass() {
  local length=${1:-10}
  pwgen -1  -B -c -n $length 1
  # 特殊記号: -s -y
}
alias aopa='~/bin/toggle_alacritty_opacity.sh'


# タイムスタンプ順にソート (最新ファイルを上に)
alias lt="eza -l --sort changed"
alias ld='eza -D'
alias la='eza -la'
if [ -n "$(which eza)" ]; then
    alias ls="eza -l --sort changed"
fi
ezt() {
  eza --tree "$@"
}


function pwd() {
  builtin pwd | tee >(pbcopy)
}
function man() {
    env LESS_TERMCAP_mb=$'\E[01;31m' \
    LESS_TERMCAP_md=$'\E[01;38;5;74m' \
    LESS_TERMCAP_me=$'\E[0m' \
    LESS_TERMCAP_se=$'\E[0m' \
    LESS_TERMCAP_so=$'\E[38;5;246m' \
    LESS_TERMCAP_ue=$'\E[0m' \
    LESS_TERMCAP_us=$'\E[04;38;5;146m' \
    man "$@"
}



function mvp() {
    target_dir=$(dirname "$2")
    if [ ! -d "$target_dir" ]; then
        mkdir -p "$target_dir"
    fi
    mv "$1" "$2"
}
function cpp() {
    # Usage: cpp <source_file> <destination_directory>
    # 指定したファイルをコピーし、コピー先ディレクトリが存在しない場合は自動作成する
    # 注意点:
    # - コピー先にファイルを指定すると意図しない動作をする可能性がある (ディレクトリを指定すること)

    if [ ! -d "$2" ]; then
        mkdir -p "$2"
    fi
    cp "$1" "$2"
}


alias cat='bat --style=plain --paging=never'
alias less='bat --style=plain'
alias ll="ls -lah --git --sort modified"
alias lt="ll -TL 3 --ignore-glob=.git"
alias ps="procs"
alias top="ytop"
alias vi="nvim"
alias vim="nvim"
alias du="dust"
alias de="defaults"
alias groot="cd ~/ghq/github.com/1206yaya"
alias icloud="cd /Users/zak/Library/Mobile Documents/com~apple~CloudDocs"
alias kraken="open -na 'GitKraken' --args -p $(pwd)"

alias refresh="source ~/.zshrc"
alias edit="code ~/.zshrc"
# 最終更新日時の新しい順にファイルを表示
alias g='dir=$(ghq list | xargs -I{} stat -f "%m %N" "$(ghq root)/{}" | sort -nr | cut -d" " -f2- | peco); [ -z "$dir" ] && return; builtin cd "$dir"'

alias pycharm="open -na 'PyCharm CE.app' --args "$@""
alias intellij="open -na 'IntelliJ IDEA CE.app' --args "$@""
# alias pulsar="open -na 'Pulsar.app' --args "$@""
alias pulsar="open -na 'Pulsar.app' --args"

alias fire="firebase "$@""
alias mk="make "$@""
alias genc="openapi-generator "$@""
alias cursor="open -a /Applications/Cursor.app "$@""
alias rege="fvm flutter pub run build_runner build --delete-conflicting-outputs; flutter pub run build_runner watch "
alias obsidian="open -a /Applications/Obsidian.app "$@""
alias pes="pet sync"
#　直前のコマンドをpet に登録
function prev() {
  PREV=$(fc -lrn | head -n 1)
  sh -c "pet new `printf %q "$PREV"`"
}
function open() {
  if [[ $@ == "pdf" ]]; then
    command open /Users/zak/Library/Mobile\ Documents/iCloud~md~obsidian/Documents/Notes/asettes/pdf
  else
    command open $@
  fi
}

function terminal() {
  CURRENT_DIR=$(pwd)

osascript <<END
tell application "iTerm"
    activate
    try
        tell current window
            create tab with default profile
        end tell
    on error
        tell application "System Events" to tell process "iTerm2"
            keystroke "t" using command down
        end tell
    end try
    tell current session of current window
        write text "cd \"$CURRENT_DIR\""
    end tell
end tell
END
}


pulsar_open() {
    if [ $# -eq 0 ]; then
        # 引数がない場合は現在のディレクトリを開く
        open -na 'Pulsar.app' --args "$PWD"
    else
        # 引数がある場合はそのパスを絶対パスに変換して開く
        open -na 'Pulsar.app' --args "$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
    fi
}

alias pulsar=pulsar_open

function npminstall (){
  npm install -g firebase-tools
  npm install -g tsc
  npm install -g typesync
  dart pub global activate flutterfire_cli
  source ~/.zshrc
}
function ghq() {
  if [[ $1 == "create" ]]; then
    command ghq create "$2" && builtin cd "$(ghq list -p | grep "$2$")" && code .
  elif [[ $1 == "get" ]]; then
    command ghq get "$2" && builtin cd "$(ghq list -p | grep "$2$")" && code .
  else
    command ghq "$@"
  fi
}
function st() {
  if [[ $@ == "" ]]; then
    command open -a /Applications/SourceTree.app .
  else
    command open -a /Applications/SourceTree.app "$@"
  fi
}
function hub() {
  if [[ $@ == "" ]]; then
    command hub browse $(ghq list | peco | cut -d "/" -f 2,3)
  else
    command hub "$@"
  fi
}


function makefile() {
  pathDir="/Users/zak/ghq/github.com/1206yaya/dotfiles/packages/terminal/.zsh/Makefile"
  # 初期の拡張子を設定
  ext="mk"

  # 引数に基づいてファイル名を構築し、ショートカットを考慮
  case "$1" in
    firebase|fir|flutterfire)
      filename="firebase.$ext"
      ;;
    py|python|poetry)
      filename="poetry.$ext"
      ;;
    open|edit)
      subl $pathDir/
      return
      ;;
    *)
      # 特に設定がない場合は引数をそのままファイル名として扱う
      filename="${1}.$ext"
      if [ ! -f "$pathDir/$filename" ]; then
          # 拡張子が.htmlの場合を考慮
          ext="html"
          filename="${1}.$ext"
      fi
      ;;
  esac

  # ファイルの存在をチェックして、存在すればその内容を表示
  if [ -f "$pathDir/$filename" ]; then
    cat "$pathDir/$filename"
  else
    echo "No makefile found for $1"
  fi
}

### クリップボードの内容を特定のフォルダにタイムスタンプ付きでファイルとして保存する
function cbf() {
  
  FOLDER_PATH=~/Downloads

  # 現在のタイムスタンプを取得します。
  TIMESTAMP=$(date "+%Y%m%d%H%M%S")

  # クリップボードの内容をファイルに保存します。
  pbpaste > "$FOLDER_PATH/$TIMESTAMP.txt"
}


grep() {
  command grep --color -E "$@"
}


function tmpdir() {
  NOW=$(date "+%Y-%m-%d%H%M")
  TMP_DIR=~/Downloads/tmp/${NOW}
  echo ${TMP_DIR}
  if [ ! -d "$TMP_DIR" ]; then
    mkdir -p "$TMP_DIR"
  fi
  builtin cd ${TMP_DIR}; code .
}


function mkcd() {
    mkdir -p "$@" && cd "$_";
}

#* ChromeのWindowタイトルに特定の文字列が含まれているもののみを終了するということはできない
# AppleScript ではプロセス ID に関連する情報を取得する機能がないから
# 閉じるときは手動で閉じるしかない
function killbrowser() {
  kill $(ps aux | grep 'selenium' | awk '{print $2}')
  kill $(ps aux | grep 'Google Chrome.app' | awk '{print $2}')
}

function chat() {
  code ~/ghq/github.com/1206yaya/prompt-engineering
}
# killPort <port>
function killport() {
    if [[ -n "$1" ]]
    then
        lsof -t -i tcp:"$1" | xargs kill
    else
        echo 'Error: please provide a port number.'
    fi
}

# この関数は、コマンド履歴の一覧を表示し、pecoで選択したコマンドを実行するものです。
function peco-history-pbcopy() {
  history -n 1 | tail -r  | awk '!a[$0]++' | peco --layout=bottom-up | tr -d "\r\n" | pbcopy 
}
# Control + hh で実行
zle -N peco-history-pbcopy
bindkey '^H^H' peco-history-pbcopy




# なんかいまいち
# https://qiita.com/masakuni-ito/items/deb000b5ca5eb6588463
function fr() {
  grep_cmd="grep --recursive --line-number --invert-match --regexp '^\s*$' * 2>/dev/null"

  if type "rg" >/dev/null 2>&1; then
      grep_cmd="rg --hidden --no-ignore --line-number --no-heading --invert-match '^\s*$' 2>/dev/null"
  fi

  read -r file line <<<"$(eval $grep_cmd | fzf --select-1 --exit-0 | awk -F: '{print $1, $2}')"
  ( [[ -z "$file" ]] || [[ -z "$line" ]] ) && exit
  $EDITOR $file +$line
}


