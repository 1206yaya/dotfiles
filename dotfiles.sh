#!/bin/sh 
set -x
set -e 
export GITHUB_EMAIL=1206yaya@gmail.com
export GIT_CLONE_PATH=~/ghq/github.com/1206yaya
export DOTDIR="$GIT_CLONE_PATH/dotfiles"

###########################################################
# Options
###########################################################
unlink_packages=
verbose=
for i in "$@"; do
    case "$i" in
        -s|--skip-apps)
            skip_apps=1
            shift ;;
        -v|--verbose)
            verbose=1
            shift ;;
        -u=*|--unlink=*)
            unlink_packages="${i#*=}"
            shift ;;
        *) ;;
    esac
done

###########################################################
# Utils
###########################################################
log() {
    message=$1
    echo "📌 $message"
}

file_exists() {
    path="$1"
    [ -f "$path" ]
}

dir_exists() {
    path="$1"
    [ -d "$path" ]
}

ensure_dir_exists() {
    path="$1"
    if ! dir_exists "$path"; then
        mkdir -p "$path"
    fi
}

###########################################################
# Install Homebrew
###########################################################
arch_name="$(uname -m)"
if [ "${arch_name}" = "x86_64" ]; then
    if ! file_exists /usr/local/bin/brew; then
        log 'Setup Homebrew'
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
    fi
elif [ "${arch_name}" = "arm64" ]; then
    if ! file_exists /opt/homebrew/bin/brew; then
        log 'Setup Homebrew'
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        eval "$(/opt/homebrew/bin/brew shellenv)"

        log 'Install Rosetta 2'
        sudo softwareupdate --install-rosetta --agree-to-license
    fi
fi


###########################################################
# Create Symbolic Links Manually
###########################################################
ln -sf "$DOTDIR/git/.gitconfig" "$HOME/.gitconfig"
ln -sf "$DOTDIR/git/.gitconfig.local" "$HOME/.gitconfig.local"
ln -sf "$DOTDIR/git/.gitignore_global" "$HOME/.gitignore_global"
echo DOTDIR: $DOTDIR
# Zsh関連ファイルのリンク
ln -sf "$DOTDIR/zsh/.zshrc" "$HOME/.zshrc"
ln -sf "$DOTDIR/zsh/.zshenv" "$HOME/.zshenv"

# .config/zsh ディレクトリ作成
mkdir -p "$HOME/.config/zsh"

# $DOTDIR/zsh/.config/ 内の全ファイルを `$HOME/.config/zsh/` にリンク
files=($DOTDIR/zsh/.config/*)

# ファイルが1つでも存在するかチェック
if [[ ${#files[@]} -gt 0 && -e ${files[1]} ]]; then
    for file in "${files[@]}"; do
        target="$HOME/.config/zsh/$(basename "$file")"
        ln -sf "$file" "$target"
    done
fi


ln -sf "$DOTDIR/.config/starship.toml" "$HOME/.config/starship.toml"

ensure_dir_exists "$GIT_CLONE_PATH"

if ! dir_exists "$DOTDIR"; then
    log "Clone dotfiles to $DOTDIR"
    cd "$GIT_CLONE_PATH"
    git clone https://github.com/1206yaya/dotfiles.git
fi

if [ ! "$skip_apps" ]; then
    log 'Install Apps and CLIs'
    brew bundle --file "$DOTDIR/Brewfile" $([ -n "$verbose" ] && echo -v)
fi



# ensure_dir_exists ~/.config/alacritty
# ln -sf "$DOTDIR/alacritty/alacritty.yml" ~/.config/alacritty/alacritty.yml

# ensure_dir_exists ~/.config/starship
# ln -sf "$DOTDIR/starship/starship.toml" ~/.config/starship/starship.toml

# ensure_dir_exists ~/.config/yarn/global
# ln -sf "$DOTDIR/yarn/global/package.json" ~/.config/yarn/global/package.json

# ###########################################################
# # Git Setup
# ###########################################################
# if ! dir_exists ~/.gnupg || [ -z "$(gpg --list-secret-keys --keyid-format LONG)" ]; then
#     log 'Install gpg signing with git'
#     gpg --default-new-key-algo rsa4096 --gen-key
#     key_id=$(gpg --list-secret-keys --keyid-format LONG | grep -oP "rsa4096/[0-9a-fA-F]{16}" | cut -d"/"  -f2)
#     log 'Copy and paste the GPG key below to GitHub'
#     gpg --armor --export "$key_id"
#     git config --global user.signingkey "$key_id"
# fi

# if ! file_exists ~/.ssh/id_rsa.pub; then
#     log 'Setup SSH key for GitHub'
#     ssh-keygen -t rsa -b 4096 -C $GITHUB_EMAIL
#     log 'Copy and paste the SSH key below to GitHub'
#     cat ~/.ssh/id_rsa.pub
# fi

# ###########################################################
# # VSCode Extensions
# ###########################################################
# VSCODE_EXTENSIONS_FILE="$DOTDIR/vscode/vscode-extensions.txt"

# INSTALLED_EXTENSIONS_COUNT=$(code --list-extensions | wc -l)

# if [ "$INSTALLED_EXTENSIONS_COUNT" -eq 0 ]; then
#     log "Installing VS Code extensions..."
#     while IFS= read -r extension; do
#         code --install-extension "$extension" --force
#         echo "installed $extension"
#     done < "$VSCODE_EXTENSIONS_FILE"
# else
#     log "Updating VS Code extensions list..."
#     code --list-extensions > "$VSCODE_EXTENSIONS_FILE"
# fi

# npm install --global @azu/github-label-setup
# poetry config virtualenvs.in-project true
