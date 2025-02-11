#!/bin/sh 

export GITHUB_EMAIL=1206yaya@gmail.com
export GIT_CLONE_PATH=~/ghq/github.com/1206yaya
export DOTDIR="$GIT_CLONE_PATH/dotfiles"

###########################################################
# Options
###########################################################
unlink_packages=
verbose=
skip_apps=0
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
log() { echo "📌 $1"; }
info() { printf '[ \033[00;34m  \033[0m ] %s\n' "$1"; }
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
press_to_continue() { info 'Press any key to continue'; read -r _; }
success() { printf '[ \033[00;32mOK\033[0m ] %s\n' "$1"; }

###########################################################
# Functions
###########################################################

install_xcode_command_line_tools() {
    if ! xcode-select -p; then
        log 'Install Xcode Command Line Tools'
        xcode-select --install
    fi
}


clone_dotfiles() {
    if ! dir_exists "$DOTDIR"; then
        log "Clone dotfiles to $DOTDIR"
        cd "$GIT_CLONE_PATH"
        git clone
    fi
}

setup_ssh() {
  mkdir -p "$HOME"/.ssh
  if [ ! -f "$HOME"/.ssh/id_ed25519.pub ]; then
    ssh-keygen -t ed25519 -C "$(git config user.email)" -f "$HOME"/.ssh/id_ed25519
    info 'Register your SSH public key on GitHub (Key Type: Authentication Key): https://github.com/settings/ssh/new'
    info 'Copy the public key below and add it to the "New SSH Key" page on GitHub, selecting "Authentication Key" as the Key Type.'
    cat "$HOME"/.ssh/id_ed25519.pub
    echo ''
    press_to_continue
  else
    success "SSH Key - Key-pair already present"
  fi
}

install_homebrew() {
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

}

install_brewfile() {
    if [ "$skip_apps" -eq 0 ]; then
        log 'Install Apps and CLIs'
        brew bundle --file "$DOTDIR/Brewfile" $([ -n "$verbose" ] && echo -v)
    fi
}

setup_gpg() {
    # # ~/.gnupg ディレクトリが存在しない、または GPG 秘密鍵がない場合に実行
    # if ! dir_exists ~/.gnupg || [ -z "$(gpg --list-secret-keys --keyid-format LONG)" ]; then
    #     log 'Install gpg signing with git' # GPG 署名のセットアップ開始

    #     # RSA4096 を使用して新しい GPG 鍵を作成
    #     gpg --default-new-key-algo rsa4096 --gen-key

    #     # 作成した GPG 鍵の Key ID を取得
        key_id=$(gpg --list-secret-keys --keyid-format LONG | ggrep -oP "rsa4096\/[0-9a-fA-F]{16}" | cut -d"/"  -f2)

    #     # GitHub に登録するための GPG 公開鍵を表示するよう通知
    #     log 'Copy and paste the GPG key below to GitHub'
        
    #     # GPG 公開鍵を表示（ユーザーが GitHub に登録するため）
    #     gpg --armor --export "$key_id"

    #     # Github URLを表示
    #     # ユーザーにコピーする時間を与える
    #     info 'Register your GPG key on GitHub : https://github.com/settings/gpg/new'
        
    #     press_to_continue

        # ~/.gitconfig.local に GPG 署名鍵の設定を追加
        git_local_config="$HOME/.gitconfig.local"

        if ! file_exists "$git_local_config"; then
            touch "$git_local_config"
        fi

        # 既存の signingkey 設定を削除（重複防止）
        sed -i '' '/signingkey/d' "$git_local_config"

        # GPG 署名キーを ~/.gitconfig.local に追加
        echo "[user]" >> "$git_local_config"
        echo "    signingkey = $key_id" >> "$git_local_config"

        log "Added GPG signing key to ~/.gitconfig.local"
    # fi
}

create_symbolic_links() {
    log 'Create Symbolic Links'
    ln -sf "$DOTDIR/git/.gitconfig" "$HOME/.gitconfig"
    ln -sf "$DOTDIR/git/.gitignore_global" "$HOME/.gitignore_global"

    ln -sf "$DOTDIR/zsh/.zshrc" "$HOME/.zshrc"
    ln -sf "$DOTDIR/zsh/.zshenv" "$HOME/.zshenv"
    mkdir -p "$HOME/.config/zsh"
    files=($DOTDIR/zsh/.config/*)
    if [[ ${#files[@]} -gt 0 && -e ${files[1]} ]]; then
        for file in "${files[@]}"; do
            target="$HOME/.config/zsh/$(basename "$file")"
            ln -sf "$file" "$target"
        done
    fi

    ln -sf "$DOTDIR/.config/starship.toml" "$HOME/.config/starship.toml"
}




install_xcode_command_line_tools
clone_dotfiles
setup_ssh
install_homebrew
install_brewfile
setup_gpg
create_symbolic_links