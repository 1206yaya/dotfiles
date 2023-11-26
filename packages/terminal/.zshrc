export PATH=$PATH:$HOME/scripts

export GIT_CLONE_PATH="$HOME"/projects/github/1206yaya
export GOKU_EDN_CONFIG_FILE="$HOME"/.config/karabiner/karabiner.edn
export HISTFILE=~/.zsh_history
export HISTSIZE=100000
export SAVEHIST=100000
setopt no_beep
setopt auto_pushd
setopt pushd_ignore_dups
setopt auto_cd
setopt hist_ignore_dups
# setopt share_history
setopt inc_append_history


# Homebrew, asdf-vm
if [ -f "/opt/homebrew/bin/brew"  ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"

    . $(brew --prefix asdf)/libexec/asdf.sh
fi
export JAVA_HOME="$(asdf where java)"
export PATH="$PATH:$HOME/fvm/default/bin"
export PATH="$PATH":"$HOME/.pub-cache/bin"
# export PATH="$HOME/.anyenv/bin:$PATH"
eval "$(anyenv init -)"

# for curl
# setopt nonomatch
alias q="exit"
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
alias gl='gcloud'
alias pt='poetry run pytest'
alias pr='poetry run'
alias flrgen='flutter pub run build_runner watch'
alias flrdel='flutter pub run build_runner build --delete-conflicting-outputs'

# Override
if [ -n "$(which z)" ]; then
    alias cd="z"
fi

if [ -n "$(which exa)" ]; then
    alias ls="exa"
fi

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
alias g='cd $(ghq root)/$(ghq list | peco); code .'
alias pycharm="open -na 'PyCharm CE.app' --args "$@""
alias intellij="open -na 'IntelliJ IDEA CE.app' --args "$@""
alias fire="firebase "$@""
alias mk="make "$@""
alias rege="fvm flutter pub run build_runner build --delete-conflicting-outputs; flutter pub run build_runner watch "
function open() {
  if [[ $@ == "pdf" ]]; then
    command open /Users/zak/Library/Mobile\ Documents/iCloud~md~obsidian/Documents/Notes/asettes/pdf
  else
    command open $@
  fi
}

function cd() {
  if [[ $@ == "notes" || $@ == "note" ]]; then
    command cd  /Users/zak/Library/Mobile\ Documents/iCloud~md~obsidian/Documents/Notes
  elif  [[ $@ == "pdf" ]]; then
    command open  /Users/zak/Library/Mobile\ Documents/iCloud~md~obsidian/Documents/Notes/asettes/pdf
  else
    command cd $@
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
  PROJECT_TYPES=("flutter" "firebase" "functions" "poetry")
  target_project_type=$1

  # Step1. target_project_typeが ROJECT_TYPES に含まれていない場合  PROJECT_TYPES を表示して終了
  if [[ ! " ${PROJECT_TYPES[@]} " =~ " ${target_project_type} " ]]; then
    echo "第１引数には、${PROJECT_TYPES[@]} のいずれかを指定してください"
    return 1
  fi
  MAKEFILE_PATH="$HOME/ghq/github.com/1206yaya/dotfiles/packages/terminal/.zsh/Makefile"
  cat ${MAKEFILE_PATH}/Makefile_${target_project_type}.mk 
}
### クリップボードの内容を特定のフォルダにタイムスタンプ付きでファイルとして保存する
function cbf() {
  
  FOLDER_PATH=~/Downloads

  # 現在のタイムスタンプを取得します。
  TIMESTAMP=$(date "+%Y%m%d%H%M%S")

  # クリップボードの内容をファイルに保存します。
  pbpaste > "$FOLDER_PATH/$TIMESTAMP.txt"
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


  grep -v '^\s*#' pubspec.yaml |grep -v '^\s*$' > pubspec.yaml_tmp; cat pubspec.yaml_tmp > pubspec.yaml ; rm -rf pubspec.yaml_tmp;
  
  echo ">>> create_dir: $create_dir"
  if [[ !create_dir ]]; then
    mv $project_name/* ./
    mv $project_name/.* ./
  fi

  code .

}
function chatutil() {
  mkdir -p chatutils
  tree -fFi -I '*.md|*.iml|Makefile|*.json|*test*|.fvm|.dart_tool|assets|.github|.vscode|.idea|*.log|l10n.yaml|*.png|dart_test.yaml|build|android|ios|macos|web|windows|linux|.gitignore|analysis_options.yaml|flutter_starter_project.iml|*.lock|pubspec.yaml|firebase_options.dart|README.md|chatutils' | grep -v '/$' | sed 's|^\./||' | grep -v '\.g\.dart$' | grep -v '\.freezed\.dart$' > chatutils/files.txt
  sed -i.bak '$d' chatutils/files.txt
  sed -i.bak '$d' chatutils/files.txt
  while IFS= read -r filepath
  do
      # Check if the file exists before trying to display its contents
      if [ ! -f "$filepath" ]; then
        continue ;
      fi
      # Print the file path
      echo "*$filepath*"
      echo ""
      echo "\`\`\`"
  grep -v '^import ' "$filepath"| grep -vE '^from .+ import .+'
  #    cat "$filepath"
      echo ""

      echo "\`\`\`"
      echo ""
  done < "chatutils/files.txt"
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
    echo "プロジェクト名に _ は使えません。半角小文字とアンダースコア（-）だけが使用可能です。"
    return 1;
  fi



  echo "Creating poetry project: $project_name"

  URL='https://github.com/1206yaya/poetry_starter'

  if [[ $create_dir == true ]]; then
    # ディレクトリを作成してそこにクローンする
    git clone $URL $project_name
    cd $project_name
  else
    # カレントディレクトリにクローンする
    git clone $URL .
  fi
  rm -rf .git

  sed -i '' "s/^name = \".*\"/name = \"$project_name\"/" pyproject.toml
  make install

  git init
  
  code .
}


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
  echo "mk init;"
  echo "mk install"

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
  builtin cd ${TMP_DIR}
}


function mkcd() {
    mkdir -p "$@" && cd "$_";
}
function touchp() {
    mkdir -p "$(dirname "$@")" && touch  "$@"
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
    # TODO
    # if status=exited size 0 then echo "status=exitedのコンテナは存在しません"
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
alias pqconn="psql -h localhost -U postgres"
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
