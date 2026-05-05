# Raycast 設定

Alfred からの移行で必要になった構成を dotfile 化したもの。

## ディレクトリ構成

```
raycast/
├── scripts/             # Raycast Script Commands
│   ├── it.sh            # Alfred `it` ワークフローの移植 (11 サイト並列検索)
│   └── itblog.sh        # 4 つの日本語技術ブログ並列検索
├── quicklinks.json      # Amazon/YouTube 等の Quicklink 定義 (手動 import 用)
└── context-dictionary/  # 自作 Raycast extension (別件)
```

## セットアップ (各マシン 1 回ずつ手動)

### 1. Script Commands を読み込ませる

Raycast → `⌘,` → Extensions → Script Commands → **Add More Directories** →
`~/ghq/github.com/1206yaya/dotfiles/raycast/scripts/` を選択。

直後に `it` / `itblog` コマンドが Raycast から起動できる。`it kubernetes` のように引数を渡す。

### 2. Quicklinks を登録

`quicklinks.json` の各エントリを Raycast UI から手動追加:

Raycast → `Create Quicklink` → name / link を `quicklinks.json` の値で入力 → keyword を設定。

Raycast 公式の一括 import 機能は無いため手動 (8 件)。

### 3. アクティベーション Hotkey

Raycast → `⌘,` → General → **Raycast Hotkey** に Alfred で使っていたキーを割当
(例: `⌘ Space`)。同時に Spotlight のショートカットを潰すこと
(System Settings → Keyboard → Keyboard Shortcuts → Spotlight)。

## メンテナンス

- 検索対象サイトの追加・変更は `scripts/it.sh` の `urls=(…)` 配列を編集して commit。
  Raycast は dotfiles の symlink を直接読むので再読み込み不要。
- 新しい Quicklink を増やしたら `quicklinks.json` にも追記しておくと、
  別マシンでセットアップする際の手順書になる。
