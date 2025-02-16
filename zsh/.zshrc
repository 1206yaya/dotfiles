
setopt no_beep
setopt auto_pushd
setopt pushd_ignore_dups
setopt auto_cd
setopt hist_ignore_dups
# setopt share_history
setopt inc_append_history
setopt NO_NOMATCH

export PATH=$PATH:$HOME/bin # dotfiles管理下のbinがリンクされる
export fpath=(~/.config/zsh/.zsh_functions $fpath)
export GOKU_EDN_CONFIG_FILE="$HOME"/.config/karabiner/karabiner.edn
export HISTFILE=~/.zsh_history
export HISTSIZE=100000
export SAVEHIST=100000
export FUNCNEST=2000
export CHROME_PATH="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
export GPG_TTY=$(tty)
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/tools/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
export PATH="$PATH:$HOME/fvm/default/bin"
export PATH="$PATH":"$HOME/.pub-cache/bin"
# export PATH=$(go env GOPATH)/bin:$PATH
export FZF_DEFAULT_COMMAND="rg --files --hidden -l -g '!.git/*' -g '!node_modules/*'"
export FZF_DEFAULT_OPTS="-m --height 100% --border --preview 'cat {}'"
export PATH="$PATH:/Users/zak/.kit/bin"

if [[ -f ~/.secrets ]]; then
    export $(grep -v '^#' ~/.secrets | xargs)
fi
# export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"
# # Homebrew, asdf-vm
if [ -f "/opt/homebrew/bin/brew"  ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"

    # . $(brew --prefix asdf)/libexec/asdf.sh
fi
# export JAVA_HOME="$(asdf where java)"
# export PATH=$PATH:$(yarn global bin)


eval "$(zoxide init zsh)" # zoxideは z コマンドの強化版
eval "$(starship init zsh)"
eval "$(atuin init zsh --disable-up-arrow)"
eval "$(/opt/homebrew/bin/mise activate zsh)"



. $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
bindkey '^e' autosuggest-accept # 補完候補を確定する


export DYLD_LIBRARY_PATH="/opt/homebrew/lib:$DYLD_LIBRARY_PATH"

# .zshの読み込み
ZSH_DIR="${HOME}/.config/zsh"

# **/*.zsh のパターンが .zsh ファイルを正しく検索できるようにする
setopt globdots
setopt extended_glob

# .zshがディレクトリで、読み取り、実行、が可能なとき
if [ -d $ZSH_DIR ] && [ -r $ZSH_DIR ] && [ -x $ZSH_DIR ]; then
    # zshディレクトリより下にある、.zshファイルの分、繰り返す
    for file in ${ZSH_DIR}/**/*.zsh; do
        echo $file
        # 読み取り可能ならば実行する
        [ -r $file ] && source $file
    done
fi

