# cmux 教科書

## 第1章 cmux とは何か

### 1.1 一言で言うと

cmux は **macOS 向けのターミナルエミュレータアプリ**。iTerm2 や Alacritty と同じカテゴリのソフトウェアだが、以下の点で大きく異なる:

- **Ghostty のターミナルエンジン**をベースにしている（描画が高速）
- **ブラウザを内蔵**している（Chromium ベース）
- **Claude Code との統合**が組み込まれている
- **プログラムから制御できる API** が充実している

```
┌─────────────────────────────────────────────┐
│              macOS ターミナルの選択肢          │
├─────────────┬───────────┬───────────────────┤
│ Terminal.app │  iTerm2   │      cmux         │
│ (標準)       │ (定番)    │ (AI時代のターミナル) │
│              │           │                   │
│ 最低限の機能  │ 多機能     │ ターミナル          │
│              │ プロファイル │ + ブラウザ          │
│              │ tmux統合   │ + Claude Code統合  │
│              │            │ + プログラマブルAPI  │
└─────────────┴───────────┴───────────────────┘
```

### 1.2 tmux との関係

名前が似ているが **cmux と tmux は全く別物**。

| 項目 | tmux | cmux |
|------|------|------|
| 種類 | ターミナルマルチプレクサ（CUI） | ターミナルエミュレータ（GUI アプリ） |
| 動作環境 | 任意のターミナル内で動く | macOS アプリとして独立 |
| ウィンドウ管理 | テキストベースの分割 | ネイティブ GUI |
| SSH 切断後の復帰 | できる（主要な用途） | できない（ローカル前提） |

cmux は tmux の機能の一部（ペイン分割、ワークスペース切り替え）を GUI で実現しつつ、tmux 互換の CLI コマンドも提供している。

### 1.3 技術的な位置づけ

```
┌──────────────────────────────────────────┐
│              cmux.app                    │
│  ┌────────────────────────────────────┐  │
│  │   Swift / AppKit (UI レイヤー)      │  │
│  │   ワークスペース管理、タブ、サイドバー  │  │
│  ├────────────────────────────────────┤  │
│  │   Ghostty Engine (ターミナル描画)    │  │
│  │   GPU アクセラレーション、フォント描画  │  │
│  ├────────────────────────────────────┤  │
│  │   Chromium (ブラウザエンジン)        │  │
│  │   Web ページ表示、DevTools          │  │
│  ├────────────────────────────────────┤  │
│  │   Unix Socket Server (IPC)         │  │
│  │   外部プログラムとの通信             │  │
│  ├────────────────────────────────────┤  │
│  │   AppleScript Bridge (sdef)        │  │
│  │   macOS スクリプティング連携         │  │
│  └────────────────────────────────────┘  │
│                                          │
│  Resources/bin/                          │
│  ├── cmux     (CLI ツール)               │
│  ├── claude   (Claude Code ラッパー)      │
│  └── open     (URL ルーティングラッパー)   │
└──────────────────────────────────────────┘
```

- **Bundle ID:** `com.cmuxterm.app`
- **バージョン:** 0.63.0（2026年3月時点）
- **インストール:** `brew install --cask cmux`

---

## 第2章 オブジェクトモデル

cmux の UI は **4層の階層構造** で構成されている。これを理解することが、CLI や AppleScript で cmux を操作する基礎になる。

### 2.1 階層構造

```
Window（ウィンドウ）
 └── Workspace / Tab（ワークスペース = タブ）
      └── Pane（ペイン = 分割領域）
           └── Surface（サーフェス = 実際のコンテンツ）
```

**実際の例:**

```
window window:1 [current]
├── workspace workspace:1 ".claude" [selected]
│   └── pane pane:2 [focused]
│       └── surface surface:2 [terminal] tty=ttys019
├── workspace workspace:2 "learn-claude-hooks"
│   ├── pane pane:3 [focused]
│   │   └── surface surface:3 [terminal] tty=ttys002
│   └── pane pane:4
│       └── surface surface:4 [terminal] tty=ttys005
└── workspace workspace:3 "voice"
    └── pane pane:5 [focused]
        └── surface surface:5 [terminal] tty=ttys006
```

### 2.2 各オブジェクトの説明

#### Window（ウィンドウ）

macOS の 1 つのウィンドウ。通常は 1 つだけ使う。複数ウィンドウも可能。

#### Workspace（ワークスペース）= Tab（タブ）

ウィンドウ内のタブ。**プロジェクト単位で切り替える**のが典型的な使い方。

```
[.claude] [learn-claude-hooks] [voice] [lemon] [praxis]
    ↑ 選択中のワークスペース
```

> **Note:** cmux の API では「Workspace」と「Tab」は同じものを指す。CLI では workspace、AppleScript では tab という名前が使われる。

#### Pane（ペイン）

ワークスペース内の**分割された領域**。1 つのワークスペースに複数のペインを持てる。

```
┌─────────────────┬─────────────────┐
│                 │                 │
│   pane:3        │   pane:4        │
│   (左半分)       │   (右半分)       │
│                 │                 │
└─────────────────┴─────────────────┘
```

#### Surface（サーフェス）

ペイン内の**実際のコンテンツ**。2 種類ある:

- **terminal** — ターミナル（シェルが動いている）。`tty` を持つ
- **browser** — 内蔵ブラウザ（Web ページを表示）

```
┌──────────────────────────────────────┐
│  surface:3 [terminal] tty=ttys002   │
│  $ claude                            │
│  ⏺ Working on task...               │
│                                      │
└──────────────────────────────────────┘
```

### 2.3 参照の方法

CLI でオブジェクトを指定する方法は 3 種類:

| 方法 | 例 | 用途 |
|------|------|------|
| **短縮参照** | `surface:2`, `workspace:1` | 最も一般的 |
| **UUID** | `0868A1F8-87FF-4A1B-...` | 一意に特定（環境変数で使用） |
| **インデックス** | `1`, `2`, `3` | 順番で指定 |

---

## 第3章 IPC（プロセス間通信）の仕組み

cmux を外部から操作する方法は **2 つ** ある。今回のショートカット実装で両方を試し、それぞれの特性がわかった。

### 3.1 Unix ソケット + CLI

#### Unix ソケットとは

**Unix ソケット**は、同じマシン上のプログラム同士が通信するための仕組み。ファイルシステム上に「ソケットファイル」として存在する。

```
$ ls -la ~/Library/Application\ Support/cmux/cmux.sock
srw-------  zak  cmux.sock
```

先頭の `s` が「ソケットファイル」であることを示す。通常のファイルとは異なり、読み書きではなく**接続して通信する**ためのエンドポイント。

```
┌──────────────┐                    ┌──────────────┐
│  cmux CLI    │ ── 接続 ──→       │  cmux.app    │
│  (クライアント) │    cmux.sock      │  (サーバー)   │
│              │ ←── JSON応答 ──   │              │
└──────────────┘                    └──────────────┘
```

**ネットワークソケット（TCP）との違い:**

| 項目 | Unix ソケット | TCP ソケット |
|------|--------------|-------------|
| 通信範囲 | 同一マシン内のみ | ネットワーク越し |
| アドレス | ファイルパス | IP:ポート |
| 速度 | 高速（カーネル内で完結） | やや遅い（プロトコルオーバーヘッド） |
| セキュリティ | ファイルパーミッションで制御 | 認証が必要 |

#### CLI の仕組み

`cmux` CLI は、ソケットに接続してコマンドを送り、結果を受け取るクライアント。

```bash
# 内部的には以下の流れ:
# 1. cmux.sock に接続
# 2. JSON-RPC で "system.identify" メソッドを呼び出し
# 3. JSON レスポンスを受信して stdout に出力
cmux identify
```

#### ソケット認証

cmux のソケットには認証の仕組みがある:

```
認証の優先順位:
1. --password フラグ
2. CMUX_SOCKET_PASSWORD 環境変数
3. Settings に保存されたパスワード
```

cmux ターミナル内では、シェルの環境変数 `CMUX_SOCKET_PATH` が自動設定されるため、認証なしで通信できる。**しかし、外部プロセス（Karabiner など）からは、ソケットの自動検出や認証が失敗することがある。**

> **今回の教訓:** Karabiner の `shell_command` から `cmux identify` を実行すると `Error: Failed to write to socket` になった。これは Karabiner の実行環境ではソケットの検出ロジックが正常に動作しなかったため。

#### CLI で使える主なコマンド

```bash
# 情報取得
cmux identify              # フォーカス中のサーフェス情報
cmux tree --all            # 全オブジェクトのツリー表示
cmux list-workspaces       # ワークスペース一覧
cmux version               # バージョン
cmux capabilities          # 利用可能な全メソッド一覧

# ワークスペース操作
cmux new-workspace --name "project" --cwd ~/projects/foo
cmux select-workspace --workspace workspace:3
cmux close-workspace --workspace workspace:3

# ペイン操作
cmux new-split right       # 右に分割
cmux new-split down        # 下に分割

# ターミナル操作
cmux send "ls -la\n"                    # テキストを送信（\n で Enter）
cmux send-key "ctrl+c"                  # キーを送信
cmux read-screen                        # 画面の内容を読み取り
cmux read-screen --scrollback --lines 100  # スクロールバック含む

# ブラウザ操作
cmux browser open "https://example.com"
cmux browser snapshot                   # DOM のスナップショット
cmux browser eval "document.title"      # JavaScript 実行
cmux browser screenshot --out /tmp/ss.png

# 通知
cmux notify --title "Done" --body "Task completed"
```

### 3.2 AppleScript（sdef）

#### AppleScript とは

macOS に組み込まれたスクリプティング言語。アプリケーションが **sdef（Scripting Definition）ファイル** を提供することで、外部から操作可能になる。

cmux は `/Applications/cmux.app/Contents/Resources/cmux.sdef` を持っている。

#### AppleScript の利点

**Unix ソケットと違い、AppleScript は macOS のアプリケーション間通信の標準的な仕組み**。そのため:

- 特別な認証が不要
- Karabiner、Automator、Shortcuts など **あらゆる macOS ツールから呼び出せる**
- プロセスの実行コンテキストに依存しない

> **今回の教訓:** ソケットが使えなかった Karabiner 環境でも、AppleScript は問題なく動作した。最終的なスクリプトでは AppleScript を採用。

#### cmux の AppleScript オブジェクトモデル

```
application "cmux"
 ├── front window          → window
 │    ├── selected tab     → tab（= workspace）
 │    │    └── focused terminal → terminal
 │    └── tabs             → 全タブ一覧
 └── terminals             → 全ターミナル一覧
```

#### 使える操作

```applescript
-- フォーカス中のターミナルの作業ディレクトリを取得
tell application "cmux"
  set w to front window
  set t to selected tab of w
  set term to focused terminal of t
  return working directory of term
end tell

-- ターミナルのプロパティを取得
tell application "cmux"
  set w to front window
  set t to selected tab of w
  set term to focused terminal of t
  return properties of term
  -- → id, name, working directory
end tell

-- 新しいタブを作成
tell application "cmux"
  set w to front window
  new tab in w
end tell

-- ターミナルを分割
tell application "cmux"
  set w to front window
  set t to selected tab of w
  set term to focused terminal of t
  split term direction right
end tell

-- テキストを入力
tell application "cmux"
  set w to front window
  set t to selected tab of w
  set term to focused terminal of t
  input text "echo hello\n" to term
end tell
```

#### コマンドラインから AppleScript を実行

```bash
# osascript コマンドで実行
osascript -e 'tell application "cmux" to return working directory of focused terminal of selected tab of front window'

# 複数行の場合
osascript -e '
tell application "cmux"
  set w to front window
  set t to selected tab of w
  set term to focused terminal of t
  return working directory of term
end tell
'
```

### 3.3 ソケット vs AppleScript の使い分け

| 観点 | Unix ソケット (CLI) | AppleScript |
|------|-------------------|-------------|
| **速度** | 高速 | やや遅い（アプリ間通信のオーバーヘッド） |
| **機能の豊富さ** | 150+ メソッド | 基本操作のみ（10数個） |
| **ブラウザ操作** | 可能（snapshot, eval, click 等） | 不可 |
| **外部からのアクセス** | ソケット認証が必要な場合あり | 常にアクセス可能 |
| **利用シーン** | cmux 内のスクリプト、フック | Karabiner、Automator 等の外部ツール |

**結論:** cmux 内から使うなら CLI、外部から使うなら AppleScript。

---

## 第4章 環境変数

cmux はターミナル内のシェルに以下の環境変数を自動的に注入する。

### 4.1 一覧

```bash
# cmux が注入する主な環境変数
CMUX_SURFACE_ID=0868A1F8-87FF-...    # このターミナルの UUID
CMUX_WORKSPACE_ID=E6293D67-C28B-...  # このワークスペースの UUID
CMUX_PANEL_ID=0868A1F8-87FF-...      # このパネルの UUID
CMUX_TAB_ID=E6293D67-C28B-...        # このタブの UUID
CMUX_SOCKET_PATH=/Users/zak/Library/Application Support/cmux/cmux.sock
CMUX_SOCKET=/Users/zak/Library/Application Support/cmux/cmux.sock
CMUX_PORT=9180                       # HTTP ポート
CMUX_BUNDLE_ID=com.cmuxterm.app
CMUX_SHELL_INTEGRATION=1             # シェル統合が有効
CMUX_BUNDLED_CLI_PATH=/Applications/cmux.app/.../bin/cmux
```

### 4.2 環境変数の用途

スクリプトやフックで「今どのターミナルにいるか」を判定するために使う。

```bash
# cmux 内かどうかの判定
if [ -n "$CMUX_SURFACE_ID" ]; then
  echo "cmux 内で実行中"
fi

# 現在のワークスペースにコマンドを送る
cmux send --workspace "$CMUX_WORKSPACE_ID" "echo hello\n"
```

---

## 第5章 Claude Code 統合

### 5.1 claude ラッパースクリプト

cmux は `Resources/bin/claude` というラッパースクリプトを提供し、PATH の先頭に挿入する。cmux 内で `claude` と打つと、本物の Claude Code の前にこのラッパーが介入する。

```
ユーザーが claude と入力
        │
        ▼
┌─────────────────────────────┐
│ cmux の claude ラッパー       │
│                             │
│ 1. cmux 内か判定             │
│    (CMUX_SURFACE_ID の有無)  │
│                             │
│ 2. ソケットが生きているか確認   │
│    (cmux ping)              │
│                             │
│ 3. フック設定を JSON で構築    │
│    SessionStart → cmux に通知 │
│    Stop → cmux に通知         │
│    Notification → cmux に通知 │
│    ...                       │
│                             │
│ 4. セッション ID を生成        │
│    (uuidgen)                 │
│                             │
│ 5. 本物の claude を exec       │
│    --session-id <uuid>       │
│    --settings <hooks-json>   │
└─────────────────────────────┘
        │
        ▼
  本物の Claude Code が起動
  (フック付きで)
```

### 5.2 注入されるフック

| イベント | 動作 |
|---------|------|
| **SessionStart** | cmux にセッション開始を通知。タブのタイトルやアイコンが変わる |
| **Stop** | Claude が応答完了した時に通知。タブに「入力待ち」表示 |
| **SessionEnd** | セッション終了時のクリーンアップ |
| **Notification** | Claude からの通知を cmux の通知システムに転送 |
| **UserPromptSubmit** | ユーザーがプロンプトを送信した時、「実行中」表示に切り替え |
| **PreToolUse** | ツール使用前に「入力待ち」をクリア（非同期） |

### 5.3 open ラッパースクリプト

cmux は `Resources/bin/open` も提供する。Claude Code が `open https://...` を実行すると、システムブラウザではなく cmux 内蔵ブラウザで開く。

```bash
# Claude Code 内で
open https://example.com
# → cmux の内蔵ブラウザがワークスペース内に開く（外部ブラウザに切り替わらない）
```

---

## 第6章 実践: 今回作ったスクリプトの解説

### 6.1 最終版のスクリプト

```bash
#!/bin/bash
# cmux-open-vscode: Karabiner から VS Code を開く

set -euo pipefail

CODE=/opt/homebrew/bin/code

# AppleScript で cmux のフォーカス中ターミナルの cwd を取得
CWD=$(osascript -e '
tell application "cmux"
  set w to front window
  set t to selected tab of w
  set term to focused terminal of t
  return working directory of term
end tell
')

"$CODE" "$CWD"
```

### 6.2 なぜこれが動くのか

```
┌───────────────────────────────────────────────────────┐
│  Karabiner (macOS カーネルレベルのキー入力監視)          │
│  9 + x を検出 → shell_command を実行                   │
└──────────┬────────────────────────────────────────────┘
           │ fork + exec
           ▼
┌───────────────────────────────────────────────────────┐
│  /bin/bash cmux-open-vscode                           │
│  (Karabiner の子プロセスとして起動)                      │
│                                                       │
│  この時点で cmux のターミナルは一切関与していない。        │
│  Claude Code セッションも中断されない。                  │
└──────────┬────────────────────────────────────────────┘
           │ osascript 実行
           ▼
┌───────────────────────────────────────────────────────┐
│  macOS Apple Event Manager                            │
│                                                       │
│  osascript → Apple Event を cmux.app に送信            │
│  cmux.app → "front window の selected tab の           │
│              focused terminal の working directory"    │
│              を返す                                    │
│                                                       │
│  これは macOS 標準のアプリ間通信。                       │
│  ソケットもポートも認証も不要。                           │
└──────────┬────────────────────────────────────────────┘
           │ CWD="/Users/zak/.claude"
           ▼
┌───────────────────────────────────────────────────────┐
│  /opt/homebrew/bin/code /Users/zak/.claude             │
│  VS Code が指定ディレクトリで起動                       │
└───────────────────────────────────────────────────────┘
```

### 6.3 ソケット方式が失敗した理由

```
Karabiner shell_command の実行環境:
  HOME=/Users/zak
  PATH=/usr/bin:/bin:/usr/sbin:/sbin    ← 最小限の PATH
  CMUX_SOCKET_PATH=<未設定>             ← cmux の環境変数なし

cmux CLI のソケット検出ロジック:
  1. CMUX_SOCKET_PATH 環境変数を確認 → 未設定
  2. デフォルトパスを試行 → 何らかの理由で失敗
     (おそらく Karabiner のサンドボックス制約)
  3. "Error: Failed to write to socket"
```

CMUX_SOCKET_PATH を明示的に `export` しても失敗した。Karabiner の実行コンテキストでは Unix ソケットへの書き込み自体が制限されている可能性がある。

AppleScript はこの制約を受けない。macOS の Apple Event は OS レベルで仲介されるため、プロセスの実行コンテキストに依存しない。

---

## 第7章 cmux でできることカタログ

### 7.1 ターミナル操作

| できること | CLI コマンド |
|-----------|-------------|
| ワークスペース作成 | `cmux new-workspace --name "project" --cwd ~/path` |
| ペイン分割 | `cmux new-split right` / `down` / `left` / `up` |
| テキスト送信 | `cmux send "command\n"` |
| キー送信 | `cmux send-key "ctrl+c"` |
| 画面読み取り | `cmux read-screen` |
| SSH 接続 | `cmux ssh user@host` |

### 7.2 ブラウザ操作

| できること | CLI コマンド |
|-----------|-------------|
| URL を開く | `cmux browser open "https://..."` |
| ページ遷移 | `cmux browser navigate "https://..."` |
| DOM スナップショット | `cmux browser snapshot` |
| JavaScript 実行 | `cmux browser eval "document.title"` |
| スクリーンショット | `cmux browser screenshot --out /tmp/ss.png` |
| クリック | `cmux browser click "button.submit"` |
| テキスト入力 | `cmux browser type "input#search" "query"` |
| Cookie 操作 | `cmux browser cookies get / set / clear` |

### 7.3 システム操作

| できること | CLI コマンド |
|-----------|-------------|
| 通知を送る | `cmux notify --title "Title" --body "Body"` |
| Markdown を表示 | `cmux markdown open README.md` |
| テーマ変更 | `cmux themes set <name>` |
| フック設定 | `cmux set-hook <event> <command>` |

### 7.4 AI ツール統合

| ツール | コマンド |
|--------|---------|
| Claude Code | `cmux` 内で `claude` と入力（自動的にラッパー経由） |
| Claude Teams | `cmux claude-teams` |
| OpenCode (omo) | `cmux omo` |
| Codex | `cmux codex install-hooks` |

---

## 付録 A: 用語集

| 用語 | 説明 |
|------|------|
| **Ghostty** | Zig 言語で書かれた高速ターミナルエミュレータ。cmux のターミナル描画エンジン |
| **sdef** | Scripting Definition。macOS アプリの AppleScript インターフェースを定義する XML ファイル |
| **Unix ソケット** | 同一マシン上のプロセス間通信に使うファイルベースのエンドポイント |
| **Apple Event** | macOS のアプリケーション間通信の仕組み。AppleScript はこれを利用する |
| **Surface** | cmux のペイン内に表示される実際のコンテンツ（ターミナルまたはブラウザ） |
| **tty** | 疑似ターミナルデバイス。各ターミナルセッションに 1 つ割り当てられる（例: ttys019） |
| **IPC** | Inter-Process Communication。プロセス間通信の総称 |
| **JSON-RPC** | JSON 形式でリモートプロシージャコールを行うプロトコル。cmux のソケット通信で使用 |

## 付録 B: ファイルパス一覧

| パス | 説明 |
|------|------|
| `/Applications/cmux.app/Contents/MacOS/cmux` | メインバイナリ |
| `/Applications/cmux.app/Contents/Resources/bin/cmux` | CLI ツール |
| `/Applications/cmux.app/Contents/Resources/bin/claude` | Claude Code ラッパー |
| `/Applications/cmux.app/Contents/Resources/bin/open` | URL ルーティングラッパー |
| `/Applications/cmux.app/Contents/Resources/cmux.sdef` | AppleScript 定義 |
| `~/Library/Application Support/cmux/cmux.sock` | Unix ソケット |
| `~/Library/Preferences/com.cmuxterm.app.plist` | アプリ設定 |
