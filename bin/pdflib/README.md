# pdflib

~/Documents/PDF/ の技術書ライブラリを管理する Python CLI ツール。

## セットアップ

```bash
cd dotfiles/bin/pdflib
uv sync  # .venv 作成 + 依存インストール
```

シェル関数は `zsh/.config/functions/functions.zsh` に定義済み。
`source ~/.zshrc` で `pdflib` / `book` コマンドが使える。

## コマンド

### pdflib scan

~/Documents/PDF/ を走査し、catalog.json を生成する。

```bash
pdflib scan
```

- PDF/epub のファイル名をパースしてメタデータを抽出
- pypdf / ebooklib で埋め込みメタデータも補完
- `_Novel/`, `unuseful/`, `_chapters/` は除外
- 著者・年が不明なエントリは `needs_review: true` で報告

出力: `~/Documents/PDF/catalog.json`

### pdflib rename

catalog.json に基づいてファイル名を正規化する。

```bash
pdflib rename          # dry-run (確認のみ)
pdflib rename --apply  # 実行
```

正規化形式: `{Author} - {Title} ({Year}).{ext}`
- author 不明: `{Title} ({Year}).{ext}`
- year 不明: `{Author} - {Title}.{ext}`
- 日本語翻訳: 末尾に `[ja]` 付与

### pdflib chapters

章ごとに分割された PDF ディレクトリを `_chapters/` に整理する。

```bash
pdflib chapters          # dry-run
pdflib chapters --apply  # 実行
```

例: `Go/100 Go Mistakes pdfs/` → `Go/_chapters/100 Go Mistakes/`

### pdflib obsidian

catalog.json から Obsidian ノートと books.base を生成する。

```bash
pdflib obsidian          # dry-run
pdflib obsidian -v       # dry-run + 生成予定ノート一覧
pdflib obsidian --apply  # 実行
```

出力先:
- ノート: `workspace/30_resources/pdf/{Title}.md`
- ビュー: `workspace/30_resources/pdf/books.base`
- テンプレート: `workspace/90_system/Templater/book.tpl.md`

### pdflib search

catalog.json をタイトル・著者・タグで検索する。

```bash
pdflib search "go"
pdflib search "kubernetes"
```

### book (シェル関数)

catalog.json を fzf で検索し、選択した PDF を開く。

```bash
book
```

## 運用フロー

```
1. pdflib scan              # カタログ構築
2. catalog.json を手動レビュー  # 不足メタデータ補完
3. pdflib chapters --apply  # 章PDF整理
4. pdflib rename --apply    # ファイル名正規化
5. pdflib obsidian --apply  # Obsidianノート生成
```

## ファイル構成

```
bin/pdflib/
  __main__.py    # CLI エントリポイント (argparse)
  catalog.py     # catalog.json CRUD, scan, rename, chapters
  parser.py      # ファイル名パース (正規表現 5パターン)
  metadata.py    # PDF/epub メタデータ抽出 (pypdf, ebooklib)
  obsidian.py    # Obsidian ノート / .base 生成
  models.py      # Book, FileFormat dataclass
  pyproject.toml # 依存管理 (uv)
```

## catalog.json スキーマ

```json
{
  "version": 1,
  "books": [{
    "id": "designing-data-intensive-applications-en",
    "title": "Designing Data-Intensive Applications",
    "author": "Martin Kleppmann",
    "year": 2017,
    "publisher": "O'Reilly Media",
    "category": "Database",
    "language": "en",
    "formats": [
      { "format": "pdf", "path": "Database/...", "original_filename": "..." }
    ],
    "has_chapters": false,
    "chapters_dir": null,
    "is_translation": false,
    "translation_of": null,
    "tags": ["database"],
    "status": "unread",
    "needs_review": false
  }]
}
```

## ファイル名パース戦略

優先度順:

| パターン | 形式 | 例 |
|---------|------|-----|
| 1 | `Author - Title-Publisher (Year)` | `Thorsten Ball - Writing an interpreter in Go (2017).pdf` |
| 2 | `Title -- Author -- ... Year -- Publisher` | `You Don't Know JS Yet -- Kyle Simpson -- 2020 -- O'Reilly.pdf` |
| 3 | `Title-Publisher (Year)` | `Pro Git-Apress (2014).pdf` |
| 4 | `Title (Year)` | `Go Design Patterns (2016).pdf` |
| 5 | `Title` (フォールバック) | `Functional Programming in Go.pdf` |

前処理: `-ja` / `-ja_doclingo.ai` / `.jp` → language:ja、`libgen.li` / `Anna's Archive` / `[Team-IRA]` → 除去
