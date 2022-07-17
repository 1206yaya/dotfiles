export PATH=$PATH:$HOME/scripts
export GIT_CLONE_PATH="$HOME"/projects/github/1206yaya
export GOKU_EDN_CONFIG_FILE="$HOME"/.config/karabiner/karabiner.edn
export HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
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
alias q="exit"
alias code="open -a 'Visual Studio Code'"
alias syncsh=". syncsh"
alias cdrepo=". cdrepo"
alias lscmd="ls ~/scripts"
alias pr="gh pr view --web"
alias prysm="~/prysm/prysm.sh"
alias lldlib="open ~/Library/Application\ Support/Electron"
alias sim="open /Applications/Xcode.app/Contents/Developer/Applications/Simulator.app/"
alias keycodes="cat /Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/System/Library/Frameworks/Carbon.framework/Versions/A/Frameworks/HIToolbox.framework/Versions/A/Headers/Events.h"


# Override
if [ -n "$(which z)" ]; then
    alias cd="z"
fi

if [ -n "$(which exa)" ]; then
    alias ls="exa"
fi

alias cat='bat --style=plain --paging=never'
alias less='bat --style=plain'
alias ll="ls -lah --git"
alias lt="ll -TL 3 --ignore-glob=.git"
# alias ps="procs"
alias top="ytop"
alias vi="nvim"
alias du="dust"
alias de="defaults"

alias gam="git add . ; git commit -m "$@""
alias wip="git add . ; git commit -m "wip""
alias refresh="source ~/.zshrc"
alias edit="code ~/.zshrc"
alias g='cd $(ghq root)/$(ghq list | peco)'
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
function gb {
  git checkout $@
}

function gnb {
  git checkout -b $@
}

grep() {
  command grep --color -E "$@"
}

function lsp() {
    ls -la ~/projects/github/1206yaya/;
}
function cdp() {
    cd ~/projects/github/1206yaya/"$@";
}
function codep() {
    code ~/projects/github/1206yaya/"$@";
}

function tmpdir() {
  NOW=$(date "+%Y-%m-%d%H%M")
  echo "$NOW"
  TMP_DIR="~/Downloads/tmp/${NOW}"
  if [ ! -d "$TMP_DIR" ]; then
    mkdir -p "$TMP_DIR"
  fi
  cd ${TMP_DIR}
}


function mkcd() {
    mkdir -p "$@" && cd "$_";
}
function touchp() {
    mkdir -p "$(dirname "$@")" && touch  "$@"
}

function kill_webdriver() {
  kill $(ps aux | grep 'selenium' | awk '{print $2}')
  kill $(ps aux | grep 'Google Chrome.app' | awk '{print $2}')
}
function killport() {
  port=$(lsof -n -i4TCP:$1 | grep LISTEN | awk '{ print $2 }')  
  kill -9 $port 
}

# ======================================  Git
# >>> ⭐️ ⭐️ workflow of repository create on github ⭐️ ⭐️
# gam 'first commit'
# ggen

function ggen() {
    # 引数がセットされていればそれをレポジトリ名に、そうでなければカレントディレクトリ名
    REPO_NAME=
    if [[ $# -eq 0 ]]; then
        CURERNT_DIR=`printf '%s\n' "${PWD##*/}"`
        REPO_NAME=$CURERNT_DIR
    else
        REPO_NAME=$@
    fi
    
    git branch -M main
    gh repo create --private $REPO_NAME
    git remote add origin https://github.com/1206yaya/${REPO_NAME}.git
    git push -u origin main
}


function gi() { curl -sL https://www.gitignore.io/api/$@ ;}


# ====================================== yarn 
alias ys='yarn start $@'
alias yis='yarn install && yarn start $@'

if [ -d "/opt/homebrew/opt/ruby/bin" ]; then
    export PATH=/opt/homebrew/opt/ruby/bin:/opt/homebrew/lib/ruby/gems/3.0.0/bin:$PATH
fi

eval "$(zoxide init zsh)"
eval "$(starship init zsh)"

export GPG_TTY=$(tty)

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



############ >>> Springboot
# 2.6.4-SNAPSHOT
function springinit {
cat <<'EOF'
spring init \
--artifactId=sample-project \
--groupId=app \
--bootVersion=2.7.1 \
--javaVersion=11 \
--language=java \
--type=gradle-project \
--packageName=app \
--name=Application \
--dependencies=lombok,web,data-jpa,postgresql \
sample-project

more info 
$ spring init --list

Notes. if you use dynamodb
    gradle.build dependencies 
        implementation group: 'software.amazon.awssdk', name: 'dynamodb-enhanced', version: '2.17.100'
EOF
}

cs() {
    # pathDir=/mnt/c/Users/1206y/github/cheat.sheet/
    pathDir="/Users/zak/ghq/github.com/1206yaya/cheet-sheet"
    if [[ $@ == "aws-dynamodb" || $@ == "dynamo" || $@ == "dynamodb" ]]; then
        cat $pathDir/dynamodb.sh
    elif  [[ $@ == "py" || $@ == "python" ]]; then
        cat $pathDir/python.sh
    elif  [[ $1 == "docker" || $1 == "dc" ]]; then
        if [[ $2 == "fix" ]]; then
            cat $pathDir/docker.fix.sh
        else
            cat $pathDir/docker.sh
        fi 
    elif  [[ $1 == "sls" || $1 == "serverless" ]]; then
        if [[ $2 == "fix" ]]; then
            cat $pathDir/sls.fix.sh
        else
            cat $pathDir/sls.sh
        fi 
    elif  [[ $@ == "copilot" || $@ == "copi" ]]; then
        cat $pathDir/copilot.sh
    elif  [[ $@ == "bash" || $@ == "sh" ]]; then
        cat $pathDir/bash.sh
    elif  [[ $@ == "git" ]]; then
        cat $pathDir/git.sh
    elif  [[ $@ == "react" ]]; then
        cat $pathDir/react.sh
    elif  [[ $@ == "ts" || $@ == "typescript" ]]; then
        cat $pathDir/typescript.sh
    elif  [[ $@ == "open" || $@ == "edit" ]]; then
        code $pathDir/

    else
        cat <<- EOF
Nothing $@ 
EOF
    fi
}


. $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
# source '/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.zsh.inc'
# source '/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.zsh.inc'
bindkey '^e' autosuggest-accept

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
