export PATH=$PATH:$HOME/scripts
export GIT_CLONE_PATH="$HOME"/projects/github/1206yaya
export GOKU_EDN_CONFIG_FILE="$HOME"/.config/karabiner/karabiner.edn
#
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
alias g="git"
alias gam="git add . ; git commit -m "$@""
alias refresh="source ~/.zshrc"
alias edit="code ~/.zshrc"
alias st='open -a /Applications/SourceTree.app '

function lsp() {
    ls -la ~/projects/github/1206yaya/;
}
function cdp() {
    cd ~/projects/github/1206yaya/"$@";
}
function codep() {
    code ~/projects/github/1206yaya/"$@";
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
# リンク切れのVolumeを削除
alias dvr='docker volume ls -qf dangling=true | xargs -r docker volume rm'
alias dl='docker container ls -a'
alias d='docker'
alias dv='docker volume $@'
alias di='docker images $@'
alias d-c='docker-compose'

############ >>> Git
# >>> workflow of repository create on github 
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

############ >>> Springboot
function springinit {
cat <<'EOF'
spring init \
--artifactId=sample-project \
--groupId=app \
--bootVersion=2.6.4-SNAPSHOT \
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
