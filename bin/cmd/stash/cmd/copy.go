package cmd

import (
	"bytes"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"sort"
	"strconv"
	"strings"
	"time"

	"github.com/spf13/cobra"
)

/*
概要:
このコマンドは現在のパスは以下で管理しているリポジトリのスタッシュの内容を、「~/Documents/stashList/${DATE}/${BRANCH}」に保存するユーティリティです。

前提条件:
これは hrbrainのghqで管理しているリポジトリと、hrbrain.worktreesのディレクトリ構成を前提としている

hrbrainのghqで管理しているリポジトリのパス: /Users/Komatsu.Aya/ghq/github.com/hrbrain/hrbrain
hrbrain.worktreesのディレクトリ構成: /Users/Komatsu.Aya/ghq/github.com/hrbrain/hrbrain.worktrees/{worktree-name}

処理内容:
このコマンドを実行すると、現在のパスからリポジトリのルートディレクトリに移動し、git worktree listを実行して、ワークツリーの一覧を表示する。
次に、スタッシュされたファイルをstashListディレクトリに保存する。

注意点:
現在のパスからリポジトリ管理のルートディレクトリに移動するには、
*/

var copyCmd = &cobra.Command{
	Use:   "copy",
	Short: "スタッシュ内容を ~/Documents/stashList/${BRANCH}/${DATE} に保存する",
	RunE: func(cmd *cobra.Command, args []string) error {
		root, err := repoRoot()
		if err != nil {
			return err
		}
		fmt.Printf("リポジトリルート: %s\n", root)

		// 1) worktree 一覧（読み取りのみ）
		if err := runGit(root, os.Stdout, os.Stderr, "worktree", "list"); err != nil {
			return err
		}

		// 2) スタッシュが無ければ正常終了
		hasStash, err := hasAnyStash(root)
		if err != nil {
			return err
		}
		if !hasStash {
			fmt.Println("スタッシュはありませんでした。保存はスキップします。")
			return nil
		}

		// 3) ブランチ名取得（DETACHEDやスラッシュ対応）
		branch, err := gitCurrentBranch(root)
		if err != nil {
			return err
		}
		safeBranch := sanitizeBranchName(branch)

		// 4) 保存先作成
		date := time.Now().Format("20060102")
		saveDir := filepath.Join(homeDir(), "Documents", "stashList", date, safeBranch)
		if err := os.MkdirAll(saveDir, 0o755); err != nil {
			return err
		}

		// 5) ファイル名（重複回避のため時分秒付与）
		timestamp := time.Now().Format("150405")
		stashFile := filepath.Join(saveDir, fmt.Sprintf("stash_%s.patch", timestamp))

		// 6) スタッシュの差分を保存（表示のみ・非破壊）
		if err := saveGitStash(root, stashFile); err != nil {
			return err
		}
		fmt.Printf("スタッシュ内容（patch）を保存しました: %s\n", stashFile)

		// 7) stashされたファイルを階層を維持して保存
		filesDir := filepath.Join(saveDir, fmt.Sprintf("files_%s", timestamp))
		if err := os.MkdirAll(filesDir, 0o755); err != nil {
			return err
		}
		if err := saveStashedFiles(root, filesDir); err != nil {
			return err
		}
		fmt.Printf("スタッシュされたファイルを保存しました: %s\n", filesDir)

		return nil
	},
}

// --- helpers ---

func homeDir() string {
	if h := os.Getenv("HOME"); h != "" {
		return h
	}
	// まず無いですが、念のため
	d, _ := os.UserHomeDir()
	return d
}

func runGit(dir string, stdout, stderr *os.File, args ...string) error {
	cmd := exec.Command("git", args...)
	cmd.Dir = dir
	cmd.Stdout = stdout
	cmd.Stderr = stderr
	return cmd.Run()
}

func runGitOut(dir string, args ...string) (string, error) {
	cmd := exec.Command("git", args...)
	cmd.Dir = dir
	out, err := cmd.Output()
	return string(out), err
}

func repoRoot() (string, error) {
	// 最優先：Git に聞く（最も正確・非破壊）
	if out, err := runGitOut(".", "rev-parse", "--show-toplevel"); err == nil {
		root := strings.TrimSpace(out)
		if root != "" {
			return root, nil
		}
	}
	// フォールバック：親を辿る（.git がファイルでもOK）
	cwd, err := os.Getwd()
	if err != nil {
		return "", err
	}
	return findRepoRootByWalking(cwd)
}

func findRepoRootByWalking(path string) (string, error) {
	for {
		gitEntry := filepath.Join(path, ".git")
		if _, err := os.Stat(gitEntry); err == nil {
			return path, nil
		}
		parent := filepath.Dir(path)
		if parent == path {
			return "", errors.New("git リポジトリ内ではありません")
		}
		path = parent
	}
}

func gitCurrentBranch(root string) (string, error) {
	// 通常ブランチ名
	if out, err := runGitOut(root, "rev-parse", "--abbrev-ref", "HEAD"); err == nil {
		return strings.TrimSpace(out), nil
	}
	// 念のため（ほぼ不要）：symbolic-full-name
	if out, err := runGitOut(root, "symbolic-ref", "--short", "HEAD"); err == nil {
		return strings.TrimSpace(out), nil
	}
	return "HEAD", nil // DETACHED でも保存先名としてはこれで十分
}

var slashOrSpecial = regexp.MustCompile(`[\/\\:\*\?"<>\|\s]+`)

func sanitizeBranchName(name string) string {
	n := strings.TrimSpace(name)
	if n == "" {
		return "unknown"
	}
	// パス区切りや NG 文字はアンダースコアへ
	n = slashOrSpecial.ReplaceAllString(n, "_")
	// 連続アンダースコアは詰める
	n = strings.Trim(n, "_")
	if n == "" {
		return "unknown"
	}
	return n
}

func hasAnyStash(root string) (bool, error) {
	out, err := runGitOut(root, "stash", "list")
	if err != nil {
		return false, err
	}
	return strings.TrimSpace(out) != "", nil
}

func saveStashedFiles(root, filesDir string) error {
	// stashされたファイルのリストを取得
	stashFiles, err := getStashedFileList(root)
	if err != nil {
		return fmt.Errorf("stashされたファイルリストの取得に失敗: %v", err)
	}

	if len(stashFiles) == 0 {
		fmt.Println("stashされたファイルはありません")
		return nil
	}

	fmt.Printf("stashされたファイル数: %d\n", len(stashFiles))

	// 各ファイルの内容を保存
	for _, filePath := range stashFiles {
		if err := saveStashedFile(root, filesDir, filePath); err != nil {
			fmt.Printf("警告: %s の保存に失敗しました: %v\n", filePath, err)
			// エラーが発生しても他のファイルは保存を続行
			continue
		}
	}

	return nil
}

func saveCurrentVersion(root, destPath, filePath string) error {
	// 現在のワーキングディレクトリの内容を取得
	currentPath := filepath.Join(root, filePath)
	content, err := os.ReadFile(currentPath)
	if err != nil {
		return fmt.Errorf("現在のファイルの読み取りに失敗 %s: %v", filePath, err)
	}

	currentVersionPath := destPath + ".current"
	return os.WriteFile(currentVersionPath, content, 0o644)
}

// 追加: 対象 stash を返す（今は最新だけ扱う。必要ならフラグ化も可）
func latestStashRef(root string) (string, error) {
	out, err := runGitOut(root, "stash", "list")
	if err != nil {
		return "", err
	}
	if strings.TrimSpace(out) == "" {
		return "", errors.New("スタッシュがありません")
	}
	// 常に最新
	return "stash@{0}", nil
}

// 置換: スタッシュ中のファイル一覧取得を -z で安全に
func getStashedFileList(root string) ([]string, error) {
	ref, err := latestStashRef(root)
	if err != nil {
		return nil, err
	}

	// 追跡ファイル（rename 後の新パスを拾う想定）
	trackedOut, err := runGitOutQP0(root, "diff", "--name-only", "-z", ref+"^1", ref)
	if err != nil || strings.TrimSpace(trackedOut) == "" {
		// フォールバック
		trackedOut, err = runGitOutQP0(root, "stash", "show", "--name-only", "-z", ref)
		if err != nil {
			return nil, fmt.Errorf("追跡ファイル一覧の取得に失敗: %v", err)
		}
	}

	// untracked 側
	var untrackedOut string
	if _, err := runGitOut(root, "rev-parse", "--verify", "-q", ref+"^3"); err == nil {
		untrackedOut, _ = runGitOutQP0(root, "ls-tree", "-r", "--name-only", "-z", ref+"^3")
	}

	// NUL 区切りをパースし、必要なら Unquote
	uniq := map[string]struct{}{}
	decode := func(s string) string {
		s = strings.TrimSpace(s)
		if len(s) >= 2 && s[0] == '"' && s[len(s)-1] == '"' {
			if u, err := strconv.Unquote(s); err == nil {
				return u
			}
		}
		return s
	}
	for _, blob := range []string{trackedOut, untrackedOut} {
		if blob == "" {
			continue
		}
		for _, raw := range strings.Split(blob, "\x00") {
			if raw == "" {
				continue
			}
			p := decode(raw)
			if p != "" {
				uniq[p] = struct{}{}
			}
		}
	}

	files := make([]string, 0, len(uniq))
	for p := range uniq {
		files = append(files, p)
	}
	sort.Strings(files)
	return files, nil
}

// 置換: stash のバージョン抽出を stash と stash^3 の両方で試す
func saveStashVersion(root, destPath, filePath string) error {
	ref, err := latestStashRef(root)
	if err != nil {
		return err
	}

	tryShow := func(spec string) ([]byte, error) {
		cmd := exec.Command("git", "show", spec)
		cmd.Dir = root
		return cmd.Output()
	}

	// 1) 通常（追跡ファイルなど）
	out, err := tryShow(fmt.Sprintf("%s:%s", ref, filePath))
	if err != nil {
		// 2) untracked 側（stash^3）を試す
		if _, e := runGitOut(root, "rev-parse", "--verify", "-q", ref+"^3"); e == nil {
			if out2, e2 := tryShow(fmt.Sprintf("%s^3:%s", ref, filePath)); e2 == nil {
				stashVersionPath := destPath + ".stash"
				return os.WriteFile(stashVersionPath, out2, 0o644)
			}
		}
		// 3) どちらにも無ければエラー
		return fmt.Errorf("stashバージョンの取得に失敗 %s: %v", filePath, err)
	}

	stashVersionPath := destPath + ".stash"
	return os.WriteFile(stashVersionPath, out, 0o644)
}

// 既存の saveGitStash を差し替え（全体パッチは維持）
func saveGitStash(root, stashFile string) error {
	ref, err := latestStashRef(root)
	if err != nil {
		return err
	}
	// 全体の patch は保存（untracked はここでも出ないことがある点は承知）
	cmd := exec.Command("git", "stash", "show", "-p", ref)
	cmd.Dir = root
	var out bytes.Buffer
	cmd.Stdout = &out
	cmd.Stderr = &out
	if err := cmd.Run(); err != nil {
		// ここは致命ではないが、呼び出し元の今の設計に合わせてエラー返す
		return fmt.Errorf("git stash show -p に失敗しました: %v\n%s", err, out.String())
	}
	return os.WriteFile(stashFile, out.Bytes(), 0o644)
}

// 既存の saveStashedFile を差し替え
func saveStashedFile(root, filesDir, filePath string) error {
	ref, err := latestStashRef(root)
	if err != nil {
		return err
	}

	// 保存先のディレクトリ構造を先に作る
	destPath := filepath.Join(filesDir, filePath)
	destDir := filepath.Dir(destPath)
	if err := os.MkdirAll(destDir, 0o755); err != nil {
		return fmt.Errorf("ディレクトリの作成に失敗 %s: %v", destDir, err)
	}

	// 1) まず stash の実体を必ず落とす（tracked / untracked 双方に対応）
	if err := saveStashVersion(root, destPath, filePath); err != nil {
		// ここで取れない場合のみ致命的
		return err
	}

	// 2) 現在版はベストエフォート
	if err := saveCurrentVersion(root, destPath, filePath); err != nil {
		fmt.Printf("警告: 現在のバージョンの保存に失敗 %s: %v\n", filePath, err)
	}

	// 3) パッチ作成はベストエフォート
	//    まず tracked 差分（ref^1..ref）を試す
	if patch, err := runGitOut(root, "diff", "--no-color", "--unified=3", ref+"^1", ref, "--", filePath); err == nil && strings.TrimSpace(patch) != "" {
		patchPath := destPath + ".patch"
		if werr := os.WriteFile(patchPath, []byte(patch), 0o644); werr != nil {
			fmt.Printf("警告: patchファイルの保存に失敗 %s: %v\n", patchPath, werr)
		}
		return nil
	}

	// tracked で取れなければ、untracked 側（ref^3）の可能性が高い
	if _, e := runGitOut(root, "rev-parse", "--verify", "-q", ref+"^3"); e == nil {
		// untracked は新規追加扱い。ここでは patch 生成をスキップし、実体(.stash)のみとする
		// 必要ならここで「/dev/null 対象の擬似パッチ」を組み立ててもOK
		fmt.Printf("情報: 新規(untracked)の可能性が高いため patch をスキップ: %s\n", filePath)
		return nil
	}

	// それ以外は何もせず終了（実体は保存済み）
	return nil
}

// 追加: Git で「ファイル名を出す系」は quotepath を無効化
func runGitOutQP0(dir string, args ...string) (string, error) {
	// 例: git -c core.quotepath=false diff --name-only -z ...
	all := append([]string{"-c", "core.quotepath=false"}, args...)
	cmd := exec.Command("git", all...)
	cmd.Dir = dir
	out, err := cmd.Output()
	return string(out), err
}
