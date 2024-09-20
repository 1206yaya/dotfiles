
## Crontab

```sh
crontab -e
```

```
# 5:00 ~ 21:30 / 7min
*/7 5-21 * * *  cd /Users/zak/Library/Mobile\ Documents/iCloud~md~obsidian/Documents/Notes; ./sync > /Users/zak/crontab.log 2>&1
*/7 5-21 * * *  cd /Users/zak/Library/Mobile\ Documents/iCloud~md~obsidian/Documents/Notes/.obsidian; ./sync > /Users/zak/crontab.log 2>&1

```

## VSCode

PATHにスペースがありバックスラッシュを使用するためstowでエラーになる
そのため、手動でLinkはりを実行する

```
PACKAGE_DIR=/Users/zak/ghq/github.com/1206yaya/dotfiles/manual-settings/vscode/Library/Application\ Support/Code/User
CODE_DIR=/Users/zak/Library/Application\ Support/Code/User

mv ~/Library/Application\ Support/Code/User/settings.json "$PACKAGE_DIR"
mv ~/Library/Application\ Support/Code/User/keybindings.json "$PACKAGE_DIR"
mv ~/Library/Application\ Support/Code/User/snippets/ "$PACKAGE_DIR"

ln -s $PACKAGE_DIR/settings.json $CODE_DIR/settings.json
ln -s $PACKAGE_DIR/keybindings.json $CODE_DIR/keybindings.json
ln -s $PACKAGE_DIR/snippets/ $CODE_DIR/snippets
```

## Cursor

```
PACKAGE_DIR=/Users/zak/ghq/github.com/1206yaya/dotfiles/packages/vscode/
CODE_DIR=/Users/zak/Library/Application\ Support/Cursor/User

ln -s $PACKAGE_DIR/settings.json $CODE_DIR/settings.json
ln -s $PACKAGE_DIR/keybindings.json $CODE_DIR/keybindings.json
ln -s $PACKAGE_DIR/snippets/ $CODE_DIR/snippets
```