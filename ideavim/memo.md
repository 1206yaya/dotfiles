

## Trouble Shooting
IdeaVim設定の再読み込み手順：

1. GolandでVimモードで次のコマンドを実行:
   :source ~/.ideavimrc

2. または、Golandを完全に再起動

3. 再起動後、Vimモードで次のコマンドを実行してマッピングを確認:
   :map <leader>

   これで <leader> で始まるすべてのマッピングが表示されます。
   もし <leader>tf が表示されなければ、マッピングが読み込まれていません。

4. デバッグ用に、一時的に以下を試してください:
   GolandのVimモードで:
   :map ,tf <Action>(RunClass)
   
   その後 ,tf を押してみる（コンマ + t + f）
   これで動作すれば、問題は <leader> の設定です。

5. 最終手段:
   - Goland を完全に終了
   - ターミナルで: rm -rf ~/Library/Caches/JetBrains/GoLand*
   - Goland を再起動
