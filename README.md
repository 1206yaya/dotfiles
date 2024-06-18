# dotfiles

dotfiles managed with
- [GNU stow](https://www.gnu.org/software/stow/)
- [Homebrew Bundle](https://github.com/Homebrew/homebrew-bundle)
- [asdf](https://asdf-vm.com/#/)

## Installation

1. Sign in to App store manually (Temporary solution. See more: <https://github.com/mas-cli/mas/issues/164>)
2. Run install

```sh
curl -o - https://raw.githubusercontent.com/1206yaya/dotfiles/master/packages/cli/scripts/dotfiles | sh
```

3. Start Yabai and skhd

```sh
brew services start yabai
brew services start skhd
# or
brew services start --all
```
Then allow accessibility permissions on `Security & Privacy` inside `System Preferences.app`

## Manual operations
haven't figure out ways to automate
- add google-japanese-ime to input sources
- `^space` to switch input source
- show battery percentage
- install
  - [Karabiner Elements](https://karabiner-elements.pqrs.org/)
  - [Vulkan SDK](https://vulkan.lunarg.com/)
  - [Postlab](https://hedge.video/postlab)
- add [Vimari](https://apps.apple.com/us/app/vimari/id1480933944?mt=12) Safari extension
 
## Installed Apps

Check [Brewfile](./Brewfile) for the latest bundle.

## Tutorial

If you like to learn how to create dotfiles, check out my [tutorial ](https://github.com/JunichiSugiura/tutorials/tree/master/dotfiles).

## packages紹介
### terminal
ターミナル関連

## うまくいかない時

* パッケージにうまくリンクがはれない

一度、リンクを全て削除してからリンクを貼りなおす

```
rm ~/.config/karabiner
stow -vd ~//Users/zak/ghq/github.com/1206yaya/dotfiles/packages -t ~ keybindiings
stow -v -d /Users/zak/ghq/github.com/1206yaya/dotfiles/packages -t ~ keybindings

LINK: .config/skhd => ../ghq/github.com/1206yaya/dotfiles/packages/keybindings/.config/skhd
LINK: .config/karabiner => ../ghq/github.com/1206yaya/dotfiles/packages/keybindings/.config/karabiner
GOKU_EDN_CONFIG_FILE=~/.config/karabiner/kara
```

## stowが作っているファイルがどうなっているかわからなくなったとき
```
ll ~ | grep packages
```

```
 .cargo -> ghq/github.com/1206yaya/dotfiles/packages/runtime/.cargo
 .default-cargo-crates -> ghq/github.com/1206yaya/dotfiles/packages/runtime/.default-cargo-crates
 .default-gems -> ghq/github.com/1206yaya/dotfiles/packages/runtime/.default-gems
 .default-golang-pkgs -> ghq/github.com/1206yaya/dotfiles/packages/runtime/.default-golang-pkgs
 .gitconfig -> ghq/github.com/1206yaya/dotfiles/packages/git/.gitconfig
 .gitignore_global -> ghq/github.com/1206yaya/dotfiles/packages/git/.gitignore_global
 .profile -> ghq/github.com/1206yaya/dotfiles/packages/terminal/.profile
 .tmux.conf -> ghq/github.com/1206yaya/dotfiles/packages/terminal/.tmux.conf
 .tool-versions -> ghq/github.com/1206yaya/dotfiles/packages/runtime/.tool-versions
 .zshrc -> ghq/github.com/1206yaya/dotfiles/packages/terminal/.zshrc
 scripts -> ghq/github.com/1206yaya/dotfiles/packages/cli/scripts
```