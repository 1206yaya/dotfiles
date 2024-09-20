export PATH=$PATH:$HOME/scripts

export GIT_CLONE_PATH="$HOME"/projects/github/1206yaya
export GOKU_EDN_CONFIG_FILE="$HOME"/.config/karabiner/karabiner.edn
export HISTFILE=~/.zsh_history
export HISTSIZE=100000
export SAVEHIST=100000
export FUNCNEST=2000
export CHROME_PATH="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
setopt no_beep
setopt auto_pushd
setopt pushd_ignore_dups
setopt auto_cd
setopt hist_ignore_dups
# setopt share_history
setopt inc_append_history
setopt NO_NOMATCH

if [[ -f ~/.secrets ]]; then
  export $(grep -v '^#' ~/.secrets | xargs)
fi
# Homebrew, asdf-vm
if [ -f "/opt/homebrew/bin/brew"  ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"

    . $(brew --prefix asdf)/libexec/asdf.sh
fi
export JAVA_HOME="$(asdf where java)"
export PATH="$PATH:$HOME/fvm/default/bin"
export PATH="$PATH":"$HOME/.pub-cache/bin"
export PATH=$(go env GOPATH)/bin:$PATH

# export PATH="$HOME/.anyenv/bin:$PATH"
# eval "$(anyenv init -)"

# for curl
# setopt nonomatch
alias q="exit"
alias qq="osascript -e 'tell application \"iTerm2\" to quit'"
# alias code="open -a 'Visual Studio Code'"
alias o="open ."
alias tm="Open -a Terminal"
alias syncsh=". syncsh"
alias cdrepo=". cdrepo"
alias lscmd="ls ~/scripts"
alias pr="gh pr view --web"
alias prysm="~/prysm/prysm.sh"
alias lldlib="open ~/Library/Application\ Support/Electron"
alias sim="open /Applications/Xcode.app/Contents/Developer/Applications/Simulator.app/"
alias iosopen="open ./ios/Runner.xcworkspace"
alias keycodes="cat /Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/System/Library/Frameworks/Carbon.framework/Versions/A/Frameworks/HIToolbox.framework/Versions/A/Headers/Events.h"
# @Flutter Alias
alias fl='flutter'
alias localip="ifconfig en0 | grep 'inet ' | awk '{ print $2 }'"
# Terraform
alias tf='terraform'
alias gl='gcloud'
alias pt='poetry run pytest'
alias pr='poetry run'
alias add="fvm flutter pub add "$@""
alias get="fvm flutter pub get"
alias fbuild='flutter pub run build_runner build'
alias fbuildf='flutter pub run build_runner build --delete-conflicting-outputs'
alias dbuild='dart run build_runner build'
alias dbuildf='dart run build_runner clean; dart run build_runner build'
alias ls="ls -lt  "$@""
alias pb="pbcopy"
alias mkdir='mkdir -p'
function touchp() { if [[ "$1" == */* ]]; then if [ ! -d "${1%/*}/" ]; then mkdir -p "${1%/*}/"; fi; fi; touch "$1" }
alias genb="git switch -c "$@""
alias ghclose="gh issue close "$@""
alias ghcreate='gh issue create --title "$@" --body "Issue description"'
alias hub='gh browse'
alias lc="pbcopy | chatutil "$@""
alias lsgrep="ls -ltr | grep "$@""
# Override
if [ -n "$(which z)" ]; then
    alias cd="z"
fi
# ランダムなパスワードを生成する
# 引数にパスワードの長さを指定できる
# デフォルトは 10
function genpass() {
  local length=${1:-10}
  pwgen -1  -B -c -n $length 1
  # 特殊記号: -s -y
}

# if [ -n "$(which exa)" ]; then
#     alias ls="exa"
# fi
function pwd() {
  builtin pwd | tee >(pbcopy)
}


function mvp() {
    target_dir=$(dirname "$2")
    if [ ! -d "$target_dir" ]; then
        mkdir -p "$target_dir"
    fi
    mv "$1" "$2"
}
function cpp() {
    if [ ! -d "$2" ]; then
        mkdir -p "$2"
    fi
    cp "$1" "$2"
}

function anki () {
  open -a Anki
  cd /Users/zak/ghq/github.com/1206yaya/anki; code .
  open 'https://medium.com/@1206yaya/list/immersion-assets-08909484bc37'
}
function clipquery() {
  code /Users/zak/ghq/github.com/AbdulRahmanAlHamali/flutter_typeahead/example


  code /Users/zak/ghq/github.com/1206yaya/clip_query_ai
  code /Users/zak/ghq/github.com/1206yaya/flutter_playground/pub_flutter_markdown

}
function atcode() {
  code /Users/zak/ghq/github.com/1206yaya/competitive-programing-go
  open 
}
function repe() {
  code /Users/zak/ghq/github.com/1206yaya/repecheck
  code /Users/zak/ghq/github.com/1206yaya/repecheck/firebase/functions
  code /Users/zak/ghq/github.com/1206yaya/repecheck/packages/flutter_app
  open -a /Applications/Google\ Chrome.app localhost:4000/firestore/default/data;

  cd /Users/zak/ghq/github.com/1206yaya/repecheck/firebase ; make start;
}
function closerepe() {

  # 検索するウィンドウタイトルの一部を指定
  WINDOW_TITLE_PART="repe"

  # wmctrlを使用してウィンドウIDを取得
  WINDOW_ID=$(wmctrl -l | grep "Code" | grep "$WINDOW_TITLE_PART" | awk '{print $1}')

  # ウィンドウが見つかった場合は閉じる
  if [ -n "$WINDOW_ID" ]; then
    wmctrl -ic "$WINDOW_ID"
    echo "ウィンドウ '$WINDOW_TITLE_PART' が閉じられました。"
  else
    echo "ウィンドウ '$WINDOW_TITLE_PART' が見つかりませんでした。"
  fi

}
function gimerge() {
  # 現在のブランチ名を取得
  local current_branch="$(git rev-parse --abbrev-ref HEAD)"
  
  # 未コミットの変更をチェック
  if [[ -n $(git status --porcelain) ]]; then
    echo "Error: There are uncommitted changes. Please commit or stash them before merging."
    return 1  # エラーコードを返して終了
  fi

  if [[ "$current_branch" == "main" ]]; then
    echo "You are already on 'main'. No need to merge."
    return 1  # エラーコードを返して終了
  fi

  # main ブランチにチェックアウト
  git checkout main

  # リモートの最新状態を取得
  git pull origin main

  # マージを実行
  git merge "$current_branch"

  if [[ $? -ne 0 ]]; then
    echo "Merge failed. Please resolve conflicts and try again."
    return 1  # エラーコードを返して終了
  fi

  # マージ後の状態をリモートにプッシュ
  git push origin main

  # マージ対象ブランチをリモートにプッシュ
  git push origin "$current_branch"

  # ブランチ名から Issue 番号を抽出
  local issue_number
  issue_number=$(echo "$current_branch" | grep -oP '(?<=#)\d+')

  # Issue 番号が見つかった場合、Issue を閉じる
  if [[ -n "$issue_number" ]]; then
    echo "Closing issue #$issue_number"
    gh issue close "$issue_number"
    
    if [[ $? -ne 0 ]]; then
      echo "Failed to close issue #$issue_number"
      return 1  # エラーコードを返して終了
    fi
  fi

  echo "Merge, push, and issue close complete."
}


alias typora="open -a /Applications/Typora.app"
alias cat='bat --style=plain --paging=never'
alias less='bat --style=plain'
alias ll="ls -lah --git --sort modified"
alias lt="ll -TL 3 --ignore-glob=.git"
# alias ps="procs"
alias top="ytop"
alias vi="nvim"
alias vim="nvim"
alias du="dust"
alias de="defaults"
alias groot="cd ~/ghq/github.com/1206yaya"
alias kraken="open -na 'GitKraken' --args -p $(pwd)"

alias refresh="source ~/.zshrc"
alias edit="code ~/.zshrc"
# 最終更新日時の新しい順にファイルを表示
alias g='dir=$(ghq list | xargs -I{} stat -f "%m %N" "$(ghq root)/{}" | sort -nr | cut -d" " -f2- | peco); [ -z "$dir" ] && return; builtin cd "$dir"'

alias pycharm="open -na 'PyCharm CE.app' --args "$@""
alias intellij="open -na 'IntelliJ IDEA CE.app' --args "$@""
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
alias obzak="cd  /Users/zak/Library/Mobile\ Documents/iCloud~md~obsidian/Documents/ZAK"
function ccd() {
  if [[ $@ == "notes" || $@ == "note" ]]; then
    command cd  /Users/zak/Library/Mobile\ Documents/iCloud~md~obsidian/Documents/Notes
  elif  [[ $@ == "pdf" ]]; then
    command open  /Users/zak/Library/Mobile\ Documents/iCloud~md~obsidian/Documents/Notes/asettes/pdf
  elif  [[ $@ == "aaa" ]]; then
    echo "aaa"
    command cd  /Users/zak/Library/Mobile\ Documents/iCloud~md~obsidian/Documents/ZAK
  else
    command cd $@
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

function poetryadddev() {
  poetry add -D black pyproject-flake8 flake8-bugbear isort mypy
cat <<EOF >>pyproject.toml
[tool.black]
target-version = ['py39']
line-length = 120

[tool.isort]
line_length = 120
multi_line_output = 3
include_trailing_comma = true
known_local_folder=['config',]

[tool.flake8]
max-line-length = 120
max-complexity = 18
ignore = "E203,E266,W503,"

[tool.mypy]
python_version = "3.9"
no_strict_optional = true
ignore_missing_imports = true
check_untyped_defs = true

[tool.pytest.ini_options]
testpaths = ["tests",]
filterwarnings = ["ignore::DeprecationWarning",]

EOF

touch Makefile
cat <<EOF >Makefile
.PHONY: tests
tests: ## run tests with poetry
    poetry run isort .
    poetry run black .
    # poetry run pflake8 .
    poetry run mypy .
    poetry run pytest
EOF

}
function makefile() {
  pathDir="/Users/zak/ghq/github.com/1206yaya/dotfiles/packages/terminal/.zsh/Makefile"
  ext="mk"
    if [[ $@ == "firebase" || $@ == "fir" || $@ == "flutterfire" ]]; then
        cat $pathDir/firebase.$ext
    elif  [[ $@ == "py" || $@ == "python" || $@ == "poetry" ]]; then
        cat $pathDir/poetry.$ext
    elif [[ $@ == "prompt" ]]; then
        cat $pathDir/prompt.html
    elif  [[ $@ == "function" ]]; then
        cat $pathDir/function.$ext
    elif  [[ $@ == "flutter" ]]; then
        cat $pathDir/flutter.$ext
    elif  [[ $@ == "venv" ]]; then
        cat $pathDir/venv.$ext
    elif  [[ $@ == "open" || $@ == "edit" ]]; then
        subl $pathDir/

    else
        cat <<- EOF
Nothing $@ 
EOF
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



# function makefile() {

#   PROJECT_TYPES=("flutter" "firebase" "functions" "poetry")
#   target_project_type=$1

#   # Step1. target_project_typeが ROJECT_TYPES に含まれていない場合  PROJECT_TYPES を表示して終了
#   if [[ ! " ${PROJECT_TYPES[@]} " =~ " ${target_project_type} " ]]; then
#     echo "第１引数には、${PROJECT_TYPES[@]} のいずれかを指定してください"
#     return 1
#   fi
#   MAKEFILE_PATH="$HOME/ghq/github.com/1206yaya/dotfiles/packages/terminal/.zsh/Makefile"
#   cat ${MAKEFILE_PATH}/{target_project_type}.mk 

### クリップボードの内容を特定のフォルダにタイムスタンプ付きでファイルとして保存する
function cbf() {
  
  FOLDER_PATH=~/Downloads

  # 現在のタイムスタンプを取得します。
  TIMESTAMP=$(date "+%Y%m%d%H%M%S")

  # クリップボードの内容をファイルに保存します。
  pbpaste > "$FOLDER_PATH/$TIMESTAMP.txt"
}
function fluttercreate() {
  project_name=$1
  gen_current_dir=false
  echo "現在のリモートの最新のFlutterのバージョンは次のとおりです。"
  fvm list remote
  current_version=$(flutter --version | grep 'Flutter' | awk '{print $2}')
  echo "使用しているFlutterのバージョン $current_version で作成していいですか？ [y/N]: "
  read -r response
  response=${response:-y}  # エンターキーを押した場合は 'y' を設定
  if [[ $response != "y" && $response != "Y" ]]; then
    echo "作成をキャンセルしました。"
    return 1
  fi

  if [[ $project_name == "." || $project_name == "./" ]]; then
    echo "カレントディレクトリに生成します"
    CURERNT_DIR=`printf '%s\n' "${PWD##*/}"`
    project_name=$CURERNT_DIR
    if [[ $project_name == *"-"* ]]; then
      echo "カレントディレクトリ名:  $project_name をプロジェクト名として使用しますが ハイフン (-) は使えません。半角小文字とアンダースコア（_）だけが使用可能です。"
      return 1;
    fi
    gen_current_dir=true
  fi
  if [[ -z $project_name ]]; then
    echo "プロジェクト名を第１引数に指定してください"
    return 1;
  fi
  if [[ $project_name == *"-"* ]]; then
    echo "プロジェクト名に - は使えません。半角小文字とアンダースコア（_）だけが使用可能です。"
    return 1;
  fi
  echo "gen_current_dir $gen_current_dir "
  if [[ $gen_current_dir == true ]]; then
    flutter create --org com.u1206yaya --project-name "$project_name" .
  else
    flutter create --org com.u1206yaya "$project_name"
    cd "$project_name"
  fi
  clean_main_comments
  clean_pubspeck_commments
  configure_gitignore
}
function clean_pubspeck_commments() {
  grep -v '^\s*#' pubspec.yaml |grep -v '^\s*$' > pubspec.yaml_tmp; cat pubspec.yaml_tmp > pubspec.yaml ; rm -rf pubspec.yaml_tmp;
}
function clean_main_comments() {
  # コメントアウトを削除
  sed '/^[[:blank:]]*\/\//d;s/#.*//' ./lib/main.dart > ./lib/main.dart.tmp
  mv ./lib/main.dart.tmp ./lib/main.dart
}

function configure_gitignore() {
  gi flutter > .gitignore
  sed -i '' -e $'1s/^/\\*\\.g\\.dart\\\n/' .gitignore
  sed -i '' -e $'1s/^/\\*\\.freezed\\.dart\\\n/' .gitignore
  sed -i '' -e $'1s/^/\\functions\\/.env\\\n/' .gitignore

  sed -i '' -e $'1s/^/\\.fvm\\/flutter_sdk\\\n/' .gitignore
  sed -i '' -e $'1s/^/firebase_options\\.dart\\\n/' .gitignore
  sed -i '' -e $'1s/^/\\android\\/key\\.properties\\\n/' .gitignore
  sed -i '' -e $'1s/^/\\*\\*\\/android\\/app\\/google-services\\.json\\\n/' .gitignore
  
  sed -i '' -e $'1s/^/\\*\\*\\/ios\\/Flutter\\/Dart-Defines\\.xcconfig\\\n/' .gitignore
  sed -i '' -e $'1s/^/\\*\\*\\/ios\\/Runner\\/GoogleService-Info\\.plist\\\n/' .gitignore

  ##! .gitignoreに次のファイルを追加するかの議論があるが、
  ##! プライベートリポジトリなので、追加しない。
  cat <<EOF >>.gitignore
# Firebase config files
lib/firebase_options.dart
ios/Runner/GoogleService-Info.plist
ios/firebase_app_id_file.json
macos/Runner/GoogleService-Info.plist
macos/firebase_app_id_file.json
android/app/google-services.json
EOF
}

function goinit() {
  project_name=$1
  create_dir=true

  if [[ $project_name == "." || $project_name == "./" ]]; then
    echo "カレントディレクトリに生成します"
    CURERNT_DIR=`printf '%s\n' "${PWD##*/}"`
    project_name=$CURERNT_DIR
    create_dir=false
  elif [[ -z $project_name ]]; then
    echo "プロジェクト名を第１引数に指定してください"
    return 1;
  fi

  if [[ $create_dir == true ]]; then
    mkdir $project_name
    cd $project_name
  fi

cat <<EOF >main.go
package main

import (
  "fmt"
)

func main() {
  fmt.Println("Hello, World!")
}
EOF

go mod init $project_name

  code .
}

function fvmcreate() {
  project_name=$1
  version=$2
  create_dir=true

  if [[ $project_name == "." || $project_name == "./" ]]; then
    echo "カレントディレクトリに生成します"
    CURERNT_DIR=`printf '%s\n' "${PWD##*/}"`
    project_name=$CURERNT_DIR
    create_dir=false
  fi
  if [[ -z $project_name ]]; then
    echo "プロジェクト名を第１引数に指定してください"
    return 1;
  fi
  if [[ $project_name == *"-"* ]]; then
    echo "プロジェクト名に - は使えません。半角小文字とアンダースコア（_）だけが使用可能です。"
    return 1;
  fi
  if [[ -z $version ]]; then
    echo "fvm で使用する flutter Version を第２引数に指定してください"
    return 1
  fi
  if [[ -z $version ]]; then
    echo "fvm で使用する flutter Version を第２引数に指定してください"
    return 1;
  fi
  echo "create flutter \nProjectName:$project_name \nVersion $version"

  fvm global $version
  fvm use $version --force
  fvm flutter create \
    --org com.u1206yaya \
    --project-name $project_name  .

  mkdir .vscode
  touch .vscode/settings.json
cat <<EOF >.vscode/settings.json
{
    // 使用するFlutter SDKのパスを指定。
	"dart.flutterSdkPath": ".fvm/flutter_sdk",
    // 検索対象からFVMのファイルを除外します。(任意)
    "search.exclude": {
        "**/.fvm": true
    },
    // ファイル監視対象からFVMのファイルを除外します。(任意)
    "files.watcherExclude": {
        "**/.fvm": true
    },
}
EOF

  clean_main_comments
  clean_pubspeck_commments
  configure_gitignore
  

cat <<EOF >>README.md
# $project_name
EOF


  
  echo ">>> create_dir: $create_dir"
  if [[ !create_dir ]]; then
    mv $project_name/* ./
    mv $project_name/.* ./
  fi

  code .

}

function genpodfile() {
  local url="https://raw.githubusercontent.com/flutter/flutter/master/packages/flutter_tools/templates/cocoapods/Podfile-ios-objc"
  local output_dir="./ios"
  local output_file="${output_dir}/Podfile"

  # Create the output directory if it does not exist
  mkdir -p "$output_dir"

  # Download the file using curl
  curl -o "$output_file" "$url"

  # Check if the download was successful
  if [[ $? -eq 0 ]]; then
    echo "Podfile has been successfully created at ${output_file}."
  else
    echo "Failed to download the Podfile. Please check the URL and try again."
  fi
}

function fvmclosing() {

  mkdir .vscode
  touch .vscode/settings.json
cat <<EOF >.vscode/settings.json
{
    // 使用するFlutter SDKのパスを指定。
	"dart.flutterSdkPath": ".fvm/flutter_sdk",
    // 検索対象からFVMのファイルを除外します。(任意)
    "search.exclude": {
        "**/.fvm": true
    },
    // ファイル監視対象からFVMのファイルを除外します。(任意)
    "files.watcherExclude": {
        "**/.fvm": true
    },
}
EOF
  # コメントアウトを削除
  sed '/^[[:blank:]]*\/\//d;s/#.*//' ./lib/main.dart > ./lib/main.dart.tmp
  mv ./lib/main.dart.tmp ./lib/main.dart

  gi flutter > .gitignore
  sed -i '' -e $'1s/^/\\*\\.g\\.dart\\\n/' .gitignore
  sed -i '' -e $'1s/^/\\*\\.freezed\\.dart\\\n/' .gitignore
  sed -i '' -e $'1s/^/\\functions\\/.env\\\n/' .gitignore


  sed -i '' -e $'1s/^/\\.fvm\\/flutter_sdk\\\n/' .gitignore
  sed -i '' -e $'1s/^/firebase_options\\.dart\\\n/' .gitignore

##! .gitignoreに次のファイルを追加するかの議論があるが、
##! プライベートリポジトリなので、追加しない。
# cat <<EOF >>.gitignore
# # Firebase config files
# lib/firebase_options.dart
# ios/Runner/GoogleService-Info.plist
# ios/firebase_app_id_file.json
# macos/Runner/GoogleService-Info.plist
# macos/firebase_app_id_file.json
# android/app/google-services.json
# EOF

cat <<EOF >>README.md
# $project_name
EOF
  code .
}

function updatepy() {
  # link file
  version_file=~/ghq/github.com/1206yaya/dotfiles/packages/runtime/.tool-versions

  latest_versions=$(asdf latest python)
  if [ -z "$1" ]; then
    new_version=$latest_versions
  else
    new_version=$1
  fi

  # ~/.tool-versionsファイルを更新
  sed -i '' "s/python [0-9]*\.[0-9]*\.[0-9]*/python $new_version/" $version_file


  asdf install python $new_version
}

function poetrycreate() {

  project_name=$1
  version=$2
  default_version="3.12"
  create_dir=true

  if [[ -z $version ]]; then
    echo -n "poetry で使用する Python の Version は $default_version を使用しますか？ [y/N]: "
    read response
    if [[ $response =~ ^[Yy]([Ee][Ss])?$ ]]; then
      echo "poetry で使用する Python の Version は $default_version を使用します"
    else
      echo "versionを第二引数に指定してください"
      return 1;
    fi
  fi

  if [[ $project_name == "." || $project_name == "./" ]]; then
    echo "カレントディレクトリに生成します"
    # .git ディレクトリが存在するか確認
    if [[ -d ".git" ]]; then
      echo -n "このコマンドはgit cloneをつかいます。現在のディレクトリには `.git` ディレクトリが存在します。削除しますか？ [y/N]: "
      read response
      if [[ $response =~ ^[Yy]([Ee][Ss])?$ ]]; then
        echo "`.git` ディレクトリを削除します。"
        rm -rf .git
      else
        echo "`.git` ディレクトリは削除されません。"
      fi
    fi
    CURERNT_DIR=`printf '%s\n' "${PWD##*/}"`
    project_name=$CURERNT_DIR
    create_dir=false
  fi
  if [[ -z $project_name ]]; then
    echo "プロジェクト名を第１引数に指定してください"
    return 1;
  fi
  if [[ $project_name == *"_"* ]]; then
    echo "プロジェクト名に _ は使えません。半角小文字とハイフン（-）だけが使用可能です。"
    return 1;
  fi



  echo "Creating poetry project: $project_name"


  TEMPLATE_DIR="/Users/zak/ghq/github.com/1206yaya/dotfiles/packages/terminal/.zsh/Makefile/poetry"
  cp -r $TEMPLATE_DIR $project_name
  cd $project_name
  # URL='https://github.com/1206yaya/poetry_starter'
  # if [[ $create_dir == true ]]; then
  #   # ディレクトリを作成してそこにクローンする
  #   git clone $URL $project_name
  #   cd $project_name
  # else
  #   # カレントディレクトリにクローンする
  #   git clone $URL .
  # fi
  # rm -rf .git

  # sed -i '' "s/^name = \".*\"/name = \"$project_name\"/" pyproject.toml
  makefile poetry > Makefile

  make setup

  git init
  
  code .
}

alias jscreate="nodecreate"
alias tsccreate="nodecreate"
function nodecreate() {
  project_name=$1
  version=$2
  default_version="20.10.0"
  create_dir=true

  if [[ $project_name == "." || $project_name == "./" ]]; then
    echo "カレントディレクトリに生成します"
    # .git ディレクトリが存在するか確認
    if [[ -d ".git" ]]; then
      echo -n "このコマンドはgit cloneをつかいます。現在のディレクトリには `.git` ディレクトリが存在します。削除しますか？ [y/N]: "
      read response
      if [[ $response =~ ^[Yy]([Ee][Ss])?$ ]]; then
        echo "`.git` ディレクトリを削除します。"
        rm -rf .git
      else
        echo "`.git` ディレクトリは削除されません。"
        return 1;
      fi
    fi
    CURERNT_DIR=`printf '%s\n' "${PWD##*/}"`
    project_name=$CURERNT_DIR
    create_dir=false
  fi

  if [[ -z $project_name ]]; then
    echo "プロジェクト名を第１引数に指定してください"
    return 1;
  fi

  if [[ -z $version ]]; then
    echo -n "nodejs で使用する Version は $default_version を使用しますか？ [y/N]: "
    read response
    if [[ $response =~ ^[Yy]([Ee][Ss])?$ ]]; then
      echo "nodejs で使用する Version は $default_version を使用します"
    else
      echo "versionを第二引数に指定してください"
      return 1;
    fi
  fi
  echo "create nodejs by asdf \nProjectName:$project_name \nVersion $version"

  URL='https://github.com/1206yaya/nodejs_starter'

  if [[ $create_dir == true ]]; then
    # ディレクトリを作成してそこにクローンする
    git clone $URL $project_name
    cd $project_name
  else
    # カレントディレクトリにクローンする
    git clone $URL .
  fi
  
  
  git init
  gi nodejs > .gitignore
  make init

  # mkdir $project_name
  # cd $project_name
  # touch .tool-versions
  # echo "nodejs $version" >> .tool-versions
  # asdf install
  # npm init -y

  mkdir .vscode
  touch .vscode/settings.json
  code .
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
# 閉じるときは全部閉じるしかない
function killbrowser() {
  # kill $(ps aux | grep 'selenium' | awk '{print $2}')
  # kill $(ps aux | grep 'Google Chrome.app' | awk '{print $2}')
}
function tv() {
  ~/ghq/github.com/1206yaya/tradingview/tv-crawler/runner-scripts/LoginCrawler.sh
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
# function killport() {
#   port=$(lsof -n -i4TCP:$1 | grep LISTEN | awk '{ print $2 }')  
#   kill -9 $port 
# }


# ====================================== yarn 
alias ys='yarn start $@'
alias yis='yarn install && yarn start $@'

if [ -d "/opt/homebrew/opt/ruby/bin" ]; then
    export PATH=/opt/homebrew/opt/ruby/bin:/opt/homebrew/lib/ruby/gems/3.0.0/bin:$PATH
fi

eval "$(zoxide init zsh)"
eval "$(starship init zsh)"

export GPG_TTY=$(tty)
# この関数は、コマンド履歴の一覧を表示し、pecoで選択したコマンドを実行するものです。
function peco-history-pbcopy() {
  history -n 1 | tail -r  | awk '!a[$0]++' | peco --layout=bottom-up | tr -d "\r\n" | pbcopy 
}
# Control + hh で実行
zle -N peco-history-pbcopy
bindkey '^H^H' peco-history-pbcopy

export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/tools/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin

export PATH=$PATH:$(yarn global bin)
export FZF_DEFAULT_COMMAND="rg --files --hidden -l -g '!.git/*' -g '!node_modules/*'"
export FZF_DEFAULT_OPTS="-m --height 100% --border --preview 'cat {}'"

############ >>>DOCKER
# docker-compose shortcut - overrides /usr/bin/dc - desktop calculator
function dc() {
  if [[ $@ == "ls" ]]; then
    command docker container ls -a ;
  else
    command docker container $@ ;
  fi
}

function ghget() {
  if [ "$#" -ne 2 ]; then
      echo "Usage: $0 <url> <directory_name>"
      exit 1
  fi

  URL=$1
  DIR_NAME=$2

  svn checkout $URL $DIR_NAME
}

function dcr() {
  if [[ $# -eq 0 ]]; then
    command docker rm $(docker ps -a -f status=exited -q) ;
  else
    command docker rm $@ ;
  fi
}
function dir() {
  docker rmi $(docker images -a -q)
}
# リンク切れのVolumeを削除
alias dvr='docker volume ls -qf dangling=true | xargs -r docker volume rm'
alias dl='docker container ls -a'
alias d='docker'
alias dv='docker volume $@'
alias di='docker images $@'
alias d-c='docker-compose'


############ >>> java application
function javainit {
  gradle init --project-name demo --package demo --type java-application --dsl groovy --test-framework junit-jupiter

}
############ >>> Springboot
# 2.6.4-SNAPSHOT
function springinit {
cat <<'EOF'
spring init \
--artifactId=sample-project \
--groupId=app \
--bootVersion=2.7.1 \
--javaVersion=17 \
--language=java \
--type=gradle-project \
--packageName=app \
--name=Application \
--dependencies=lombok,web,data-jpa,postgresql \
sample-project

more info 
$ spring init --list
https://start.spring.io/

Notes. 
If you use Selenide 5.25.0 then --bootVersion=2.6.4-SNAPSHOT.

if you use dynamodb
    gradle.build dependencies 
        implementation group: 'software.amazon.awssdk', name: 'dynamodb-enhanced', version: '2.17.100'
EOF
}

myjupyter() {
  cd /Users/zak/ghq/github.com/1206yaya/py-jupyter-notebooks && make run
}



. $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
# source '/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.zsh.inc'
# source '/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.zsh.inc'
bindkey '^e' autosuggest-accept

# .zshの読み込み
ZSH_DIR="${HOME}/.zsh"

# .zshがディレクトリで、読み取り、実行、が可能なとき
if [ -d $ZSH_DIR ] && [ -r $ZSH_DIR ] && [ -x $ZSH_DIR ]; then
    # zshディレクトリより下にある、.zshファイルの分、繰り返す
    for file in ${ZSH_DIR}/**/*.zsh; do
        # 読み取り可能ならば実行する
        [ -r $file ] && source $file
    done
fi

#* postgresql

alias pqstart="brew services start postgresql"
alias pg="psql postgres"
alias pqconn="psql -h localhost -U zak"
function pqhelp() {
mdcat <<'EOF'

EOF
}

function showinfo() {
  echo arch: $(uname -m)
}


# showinfo

export LF_ICONS="\
tw=:\
st=:\
ow=:\
dt=:\
di=:\
fi=:\
ln=:\
or=:\
ex=:\
*.c=:\
*.cc=:\
*.clj=:\
*.coffee=:\
*.cpp=:\
*.css=:\
*.d=:\
*.dart=:\
*.erl=:\
*.exs=:\
*.fs=:\
*.go=:\
*.h=:\
*.hh=:\
*.hpp=:\
*.hs=:\
*.html=:\
*.java=:\
*.jl=:\
*.js=:\
*.json=:\
*.lua=:\
*.md=:\
*.php=:\
*.pl=:\
*.pro=:\
*.py=:\
*.rb=:\
*.rs=:\
*.scala=:\
*.ts=:\
*.vim=:\
*.cmd=:\
*.ps1=:\
*.sh=:\
*.bash=:\
*.zsh=:\
*.fish=:\
*.tar=:\
*.tgz=:\
*.arc=:\
*.arj=:\
*.taz=:\
*.lha=:\
*.lz4=:\
*.lzh=:\
*.lzma=:\
*.tlz=:\
*.txz=:\
*.tzo=:\
*.t7z=:\
*.zip=:\
*.z=:\
*.dz=:\
*.gz=:\
*.lrz=:\
*.lz=:\
*.lzo=:\
*.xz=:\
*.zst=:\
*.tzst=:\
*.bz2=:\
*.bz=:\
*.tbz=:\
*.tbz2=:\
*.tz=:\
*.deb=:\
*.rpm=:\
*.jar=:\
*.war=:\
*.ear=:\
*.sar=:\
*.rar=:\
*.alz=:\
*.ace=:\
*.zoo=:\
*.cpio=:\
*.7z=:\
*.rz=:\
*.cab=:\
*.wim=:\
*.swm=:\
*.dwm=:\
*.esd=:\
*.jpg=:\
*.jpeg=:\
*.mjpg=:\
*.mjpeg=:\
*.gif=:\
*.bmp=:\
*.pbm=:\
*.pgm=:\
*.ppm=:\
*.tga=:\
*.xbm=:\
*.xpm=:\
*.tif=:\
*.tiff=:\
*.png=:\
*.svg=:\
*.svgz=:\
*.mng=:\
*.pcx=:\
*.mov=:\
*.mpg=:\
*.mpeg=:\
*.m2v=:\
*.mkv=:\
*.webm=:\
*.ogm=:\
*.mp4=:\
*.m4v=:\
*.mp4v=:\
*.vob=:\
*.qt=:\
*.nuv=:\
*.wmv=:\
*.asf=:\
*.rm=:\
*.rmvb=:\
*.flc=:\
*.avi=:\
*.fli=:\
*.flv=:\
*.gl=:\
*.dl=:\
*.xcf=:\
*.xwd=:\
*.yuv=:\
*.cgm=:\
*.emf=:\
*.ogv=:\
*.ogx=:\
*.aac=:\
*.au=:\
*.flac=:\
*.m4a=:\
*.mid=:\
*.midi=:\
*.mka=:\
*.mp3=:\
*.mpc=:\
*.ogg=:\
*.ra=:\
*.wav=:\
*.oga=:\
*.opus=:\
*.spx=:\
*.xspf=:\
*.pdf=:\
*.nix=:\
"

export EXA_COLORS="da=37:uu=37;1:un=37:gu=37;1:gn=37:sb=33:sn=33;1"
export EXA_COLORS="ur=37:uw=37:ux=37;1:ue=37;1:$EXA_COLORS" # user file permissions
export EXA_COLORS="gr=37:gw=37:gx=37;1:$EXA_COLORS" # group file permissions
export EXA_COLORS="tr=37:tw=37:tx=37;1:$EXA_COLORS" # world file permissions
export EXA_COLORS="*.rb=33:$EXA_COLORS" # world file permissions

man() {
    env LESS_TERMCAP_mb=$'\E[01;31m' \
    LESS_TERMCAP_md=$'\E[01;38;5;74m' \
    LESS_TERMCAP_me=$'\E[0m' \
    LESS_TERMCAP_se=$'\E[0m' \
    LESS_TERMCAP_so=$'\E[38;5;246m' \
    LESS_TERMCAP_ue=$'\E[0m' \
    LESS_TERMCAP_us=$'\E[04;38;5;146m' \
    man "$@"
}


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


export DYLD_LIBRARY_PATH="/opt/homebrew/lib:$DYLD_LIBRARY_PATH"

# grit
export GRIT_INSTALL="$HOME/.grit"
export PATH="$GRIT_INSTALL/bin:$PATH"
export PATH="/usr/local/opt/postgresql@16/bin:$PATH"

## [Completion]
## Completion scripts setup. Remove the following line to uninstall
[[ -f /Users/zak/.dart-cli-completion/zsh-config.zsh ]] && . /Users/zak/.dart-cli-completion/zsh-config.zsh || true
## [/Completion]


export PATH="$PATH:/Users/zak/.kit/bin"