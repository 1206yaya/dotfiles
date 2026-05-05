# Raycast 設定

Alfred からの移行で必要になった構成を dotfile 化したもの。

## ディレクトリ構成

```
raycast/
├── scripts/                    # Raycast Script Commands
│   ├── it.sh                   # Alfred `it` ワークフローの移植 (11 サイト並列検索)
│   └── itblog.sh               # 4 つの日本語技術ブログ並列検索
├── quicklinks.json             # Amazon/YouTube 等の Quicklink 定義 (手動 import 用 / 履歴管理目的)
├── raycast-export.rayconfig    # Raycast 設定一式 (Hotkey / Quicklinks / Snippets / 拡張機能リスト等)
└── context-dictionary/         # 自作 Raycast extension (別件)
```

## セットアップ (各マシン 1 回ずつ手動)

### 1. Raycast 設定を一括 import (Hotkey / Quicklinks / Snippets ほぼ全部)

`bin/dotfiles` bootstrap を流した時に Raycast 未起動なら、
自動で `raycast-export.rayconfig` の Import ダイアログが開く。

手動でやり直す場合:
```sh
open ~/ghq/github.com/1206yaya/dotfiles/raycast/raycast-export.rayconfig
```
パスワード入力 → Import → Activation Hotkey / Quicklinks / Snippets / 拡張機能一覧
が一括反映される。

> 既存マシンの Raycast 設定を上書きするので、慎重に。

### 2. Script Commands ディレクトリ登録 (Cloud Sync 対象外なので手動)

Raycast → `⌘,` → Extensions → Script Commands → **Add More Directories** →
`~/ghq/github.com/1206yaya/dotfiles/raycast/scripts/` を選択。

直後に `it` / `itblog` コマンドが Raycast から起動できる。`it kubernetes` のように引数を渡す。

### 3. (補足) Quicklinks 個別追加

`raycast-export.rayconfig` の Import で全部入るので通常不要。
import せず個別に足す場合は `quicklinks.json` の各行を Raycast → `Create Quicklink` で入力。

### 4. (補足) Hotkey

`raycast-export.rayconfig` Import 後は元マシンと同じ Hotkey が設定済み。
別 Hotkey にしたい場合は `⌘,` → General → **Raycast Hotkey**。

## メンテナンス

- 検索対象サイトの追加・変更は `scripts/it.sh` の `urls=(…)` 配列を編集して commit。
  Raycast は dotfiles の symlink を直接読むので再読み込み不要。
- 新しい Quicklink を増やしたら `quicklinks.json` にも追記しておくと、
  別マシンでセットアップする際の手順書になる。

### `.rayconfig` の更新（重要）

Raycast の設定 (Hotkey / Quicklinks / Snippets / 拡張機能リスト) を変更したら、
**手動で export を取り直して commit する必要がある**（Pro でない場合 Cloud Sync 不可のため）:

1. Raycast → `⌘,` → Advanced → **Export**
2. パスワードは前回と同じものを入力
3. デフォルトの `~/Downloads/Raycast.rayconfig` で保存
4. `mv ~/Downloads/Raycast*.rayconfig ~/ghq/github.com/1206yaya/dotfiles/raycast/raycast-export.rayconfig`
5. `cd ~/ghq/github.com/1206yaya/dotfiles && git add raycast/raycast-export.rayconfig && git commit -m "chore(raycast): update settings export" && git push`

設定変更の頻度が高いと運用負担になるため、頻繁に変えるなら Raycast Pro ($8/月) の Cloud Sync の方が現実的。
