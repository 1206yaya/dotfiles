#!/bin/sh

# macOS のデフォルト設定を構成するスクリプト

echo 📌 Configuring macOS default settings
###########################################################
# Debug方法
# システムをログアウトして再ログインすることで適用されます
# osascript -e 'tell application "System Events" to log out'
###########################################################

# システム環境設定が開いている場合は閉じる（設定の変更を妨げないようにする）
# macOS 13+ では "System Settings" に名称変更
osascript -e 'tell application "System Settings" to quit' 2>/dev/null || true

# ターミナルの警告音を無効化
defaults write com.apple.terminal Bell -bool false

###########################################################
# 一般設定
###########################################################
# macOS の UI をダークモードに設定
defaults write "Apple Global Domain" AppleInterfaceStyle -string Dark

# Cocoa アプリのウィンドウリサイズ速度を高速化
defaults write NSGlobalDomain NSWindowResizeTime -float 0.001

# アプリを開く際の確認ダイアログを無効化
defaults write com.apple.LaunchServices LSQuarantine -bool false

# Mission Control のスペース自動並び替えを無効化
defaults write com.apple.dock mru-spaces -bool false

###########################################################
# キーボード
###########################################################
# キーの長押しで特殊文字メニューを開く機能を無効化し、キーリピートを有効化
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# キーリピート速度を最大に設定
defaults write NSGlobalDomain KeyRepeat -int 1
# キーリピート開始までの時間を短縮
defaults write NSGlobalDomain InitialKeyRepeat -int 10
# Fnキーを押さずにF1～F12を機能キーとして動作させる
defaults write -g com.apple.keyboard.fnState -bool true

###########################################################
# トラックパッド・マウス
###########################################################
# トラックパッドのクリック感度を最大に設定
defaults write com.apple.AppleMultitouchTrackpad FirstClickThreshold -int 0
defaults write com.apple.AppleMultitouchTrackpad SecondClickThreshold -int 0

# トラックパッドのカーソル速度を高速化
defaults write -g com.apple.trackpad.scaling -float 2.5

# マウスのカーソル速度を高速化
defaults write -g com.apple.mouse.scaling -float 2.5

# マウスのボタン設定を2ボタンに設定
defaults write com.apple.driver.AppleBluetoothMultitouch.mouse MouseButtonMode TwoButton

# 3本指タップを有効化
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerTapGesture -int 2

# スクロール方向をナチュラルにしない（従来の方式）
defaults write -g com.apple.swipescrolldirection -bool false

###########################################################
# 言語設定
###########################################################
# 起動時のログイン画面に言語メニューを表示
# sudo defaults write /Library/Preferences/com.apple.loginwindow showInputMenu -bool true

###########################################################
# Dock の設定
###########################################################
# Dock を自動的に非表示にする
defaults write com.apple.dock autohide -bool true
# Dock の非表示・表示の遅延をなくす
defaults write com.apple.dock autohide-delay -float 0
# Dock のアニメーション速度を最速にする
defaults write com.apple.dock autohide-time-modifier -float 0
# Dock の位置を画面下部に固定
defaults write com.apple.dock orientation -string bottom
# Dock アイコンのサイズを小さくする
defaults write com.apple.dock tilesize -float 24

###########################################################
# メニューバー
###########################################################
# メニューバーを自動的に非表示にする
# defaults write NSGlobalDomain _HIHideMenuBar -bool true

###########################################################
# Spaces（仮想デスクトップ）
###########################################################
# アニメーションを減らす（動作を高速化）
defaults write com.apple.Accessibility ReduceMotionEnabled -bool true

###########################################################
# Finder の設定
###########################################################
# Finder を完全に終了できるようにする
defaults write com.apple.finder QuitMenuItem -bool true

# Finder のアニメーションを無効化（動作を高速化）
defaults write com.apple.finder DisableAllAnimations -bool true

# 隠しファイルを表示する
defaults write com.apple.finder AppleShowAllFiles YES

# デスクトップに外部ドライブ、サーバー、リムーバブルメディアを表示する
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
defaults write com.apple.finder ShowHardDrivesOnDesktop -bool true
defaults write com.apple.finder ShowMountedServersOnDesktop -bool true
defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true

# ディスクがマウントされた際に Finder ウィンドウを自動で開く
defaults write com.apple.frameworks.diskimages auto-open-ro-root -bool true
defaults write com.apple.frameworks.diskimages auto-open-rw-root -bool true
defaults write com.apple.finder OpenWindowForNewRemovableDisk -bool true

# Finder のデフォルト表示形式をカラムビューに設定
# 形式の種類: `icnv`（アイコン）、`clmv`（カラム）、`Flwv`（ギャラリー）、`Nlsv`（リスト）
defaults write com.apple.finder FXPreferredViewStyle -string "clmv"

# ゴミ箱を空にする前の警告を無効化
defaults write com.apple.finder WarnOnEmptyTrash -bool false

# ~/Library フォルダを表示
# chflags nohidden ~/Library && xattr -d com.apple.FinderInfo ~/Library

# /Volumes フォルダを表示
# sudo chflags nohidden /Volumes

###########################################################
# スクリーンショットの設定
###########################################################
# スクリーンショットの保存先を ~/screenshots に変更
defaults write com.apple.screencapture location -string "${HOME}/screenshots"

###########################################################
# Hammerspoon  override the default location
###########################################################
defaults write org.hammerspoon.Hammerspoon MJConfigFile "~/.config/hammerspoon/init.lua"

###########################################################
# キーボードショートカット（plist からインポート）
###########################################################
MACOS_DIR="${DOTDIR:+$DOTDIR/macos}"
MACOS_DIR="${MACOS_DIR:-$(cd "$(dirname "$0")" && pwd)}"
if [ -f "$MACOS_DIR/symbolichotkeys.plist" ]; then
    defaults import com.apple.symbolichotkeys "$MACOS_DIR/symbolichotkeys.plist"
    /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
    echo "[ OK ] Imported keyboard shortcuts from symbolichotkeys.plist"
fi
