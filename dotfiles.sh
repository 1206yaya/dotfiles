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
press_to_continue() { info 'Press any key to continue'; read -r _; }


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


create_symbolic_links() {
    log 'Create Symbolic Links'
    ln -sf "$DOTDIR/.gitconfig" "$HOME/.gitconfig"
    ln -sf "$DOTDIR/.gitconfig.local" "$HOME/.gitconfig.local"
    ln -sf "$DOTDIR/.gitignore_global" "$HOME/.gitignore_global"

    ln -sf "$DOTDIR/.zshrc" "$HOME/.zshrc"
    ln -sf "$DOTDIR/.zshenv" "$HOME/.zshenv"
    mkdir -p "$HOME/.config/zsh"
    files=($DOTDIR/.config/*)
    if [[ ${#files[@]} -gt 0 && -e ${files[1]} ]]; then
        for file in "${files[@]}"; do
            target="$HOME/.config/zsh/$(basename "$file")"
            ln -sf "$file" "$target"
        done
    fi

    ln -sf "$DOTDIR/.config/starship.toml" "$HOME/.config/starship.toml"
    ln -sf "$DOTDIR/.config/yarn/global/package.json" "$HOME/.config/yarn/global/package.json"
    ln -sf "$DOTDIR/.config/alacritty/alacritty.yml" "$HOME/.config/alacritty/alacritty.yml"
    ln -sf "$DOTDIR/.config/starship/starship.toml" "$HOME/.config/starship/starship.toml"
}




install_xcode_command_line_tools
clone_dotfiles
setup_ssh
install_homebrew
install_brewfile
create_symbolic_links