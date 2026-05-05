

export LANG=en_US.UTF-8

export EDITOR=neovim

# Apple Silicon の Homebrew を non-login shell でも PATH に乗せる
# (ssh host 'brew ...' や CI のような non-interactive 実行で必要)
if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi
