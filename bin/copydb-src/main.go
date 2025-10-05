package main

import (
	"errors"
	"flag"
	"fmt"
	"io"
	"io/fs"
	"log"
	"os"
	"path/filepath"
	"strings"
)

var (
	appFlag    = flag.String("app", "all", "対象アプリ: bengal | persia | all")
	forceFlag  = flag.Bool("force", false, "コピー先を強制上書き（既存を削除）")
	dryRunFlag = flag.Bool("dry-run", false, "実行せず内容のみ表示")
	verbose    = flag.Bool("verbose", false, "詳細ログ")
)

func main() {
	log.SetFlags(0)
	flag.Parse()

	cwd, err := os.Getwd()
	must(err)

	wtRoot := getenvDefault("WT_ROOT", filepath.Join(os.Getenv("HOME"), "wt"))
	ghqRoot := getenvDefault("GHQ_ROOT", filepath.Join(os.Getenv("HOME"), "ghq"))

	targetName, worktreesRoot, err := detectTargetFromCWD(cwd)
	if err != nil {
		// フォールバック: WT_ROOT から辿る（手動で対象名を引数に指定してもOKにしたいなら拡張可）
		must(fmt.Errorf("実行パスから <対象> を特定できませんでした: %w\n現在パス: %s", err, cwd))
	}

	if *verbose {
		log.Printf("detected target: %q", targetName)
		log.Printf("worktrees root : %s", worktreesRoot)
		log.Printf("WT_ROOT        : %s", wtRoot)
		log.Printf("GHQ_ROOT       : %s", ghqRoot)
	}

	// パス定義
	srcBengal := filepath.Join(ghqRoot, "github.com/hrbrain/hrbrain/apps/bengal/app/.data")
	srcPersia := filepath.Join(ghqRoot, "github.com/hrbrain/hrbrain/apps/persia/app/.data")

	destBase := filepath.Join(wtRoot, "github.com/hrbrain/hrbrain/worktrees", targetName)
	destBengal := filepath.Join(destBase, "apps/bengal/app/.data")
	destPersia := filepath.Join(destBase, "apps/persia/app/.data")

	// app 選択
	type job struct {
		src  string
		dest string
		name string
	}
	var jobs []job
	switch strings.ToLower(*appFlag) {
	case "bengal":
		jobs = append(jobs, job{srcBengal, destBengal, "bengal"})
	case "persia":
		jobs = append(jobs, job{srcPersia, destPersia, "persia"})
	case "all", "":
		jobs = append(jobs, job{srcBengal, destBengal, "bengal"}, job{srcPersia, destPersia, "persia"})
	default:
		must(fmt.Errorf("unknown --app=%q (bengal|persia|all)", *appFlag))
	}

	// 実行
	for _, j := range jobs {
		if err := copyDataDir(j.src, j.dest, *forceFlag, *dryRunFlag, *verbose); err != nil {
			must(fmt.Errorf("%s のコピーで失敗: %w", j.name, err))
		}
	}

	if *dryRunFlag {
		log.Println("[DRY-RUN] 完了（実際のコピーはしていません）")
	} else {
		log.Println("コピー完了")
	}
}

// 実行パスから .../worktrees/<対象>/ を検出して <対象> を返す。
// 例: /Users/you/wt/github.com/hrbrain/hrbrain/worktrees/PER-XXXX/apps/... => "PER-XXXX"
func detectTargetFromCWD(cwd string) (target string, worktreesRoot string, err error) {
	parts := splitAll(filepath.Clean(cwd))
	for i := 0; i < len(parts); i++ {
		if parts[i] == "worktrees" {
			if i+1 < len(parts) {
				return parts[i+1], filepath.Join(parts[:i+1]...), nil
			}
			return "", "", errors.New("worktrees の直下に <対象> が見つかりません")
		}
	}
	return "", "", errors.New("パス中に worktrees が見つかりません")
}

func splitAll(p string) []string {
	var out []string
	for {
		dir, base := filepath.Dir(p), filepath.Base(p)
		if base == "." || base == string(os.PathSeparator) {
			if dir == p {
				break
			}
			p = dir
			continue
		}
		out = append([]string{base}, out...)
		if dir == p {
			break
		}
		p = dir
	}
	// ルートまで含めるため再構築
	full := []string{}
	cur := string(os.PathSeparator)
	for _, seg := range out {
		if cur == string(os.PathSeparator) {
			cur = filepath.Join(cur, seg)
		} else {
			cur = filepath.Join(cur, seg)
		}
		full = append(full, seg)
	}
	return out
}

func copyDataDir(src, dest string, force, dryRun, verbose bool) error {
	// src 存在チェック
	if fi, err := os.Stat(src); err != nil || !fi.IsDir() {
		return fmt.Errorf("コピー元が存在しないかディレクトリではありません: %s", src)
	}

	// 先に親作成
	parent := filepath.Dir(dest)
	if verbose {
		log.Printf("prepare dest parent: %s", parent)
	}
	if !dryRun {
		if err := os.MkdirAll(parent, 0o755); err != nil {
			return err
		}
	}

	// 既存処理
	if _, err := os.Stat(dest); err == nil {
		if !force {
			return fmt.Errorf("コピー先が既に存在します（--force で上書き）: %s", dest)
		}
		if verbose {
			log.Printf("--force 指定のため既存削除: %s", dest)
		}
		if !dryRun {
			if err := os.RemoveAll(dest); err != nil {
				return fmt.Errorf("既存削除に失敗: %w", err)
			}
		}
	}

	log.Printf("copy: %s -> %s", src, dest)
	if dryRun {
		return nil
	}
	return copyDirRecursive(src, dest, verbose)
}

func copyDirRecursive(src, dest string, verbose bool) error {
	return filepath.WalkDir(src, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		rel, _ := filepath.Rel(src, path)
		target := filepath.Join(dest, rel)

		info, _ := d.Info()

		switch {
		case d.Type()&fs.ModeSymlink != 0:
			// シンボリックリンクはリンクとしてコピー
			linkTarget, err := os.Readlink(path)
			if err != nil {
				return err
			}
			if verbose {
				log.Printf("ln -s %s -> %s", linkTarget, target)
			}
			if err := os.MkdirAll(filepath.Dir(target), 0o755); err != nil {
				return err
			}
			return os.Symlink(linkTarget, target)

		case d.IsDir():
			if verbose {
				log.Printf("mkdir %s", target)
			}
			return os.MkdirAll(target, info.Mode())

		default:
			if err := os.MkdirAll(filepath.Dir(target), 0o755); err != nil {
				return err
			}
			if verbose {
				log.Printf("cp %s -> %s", path, target)
			}
			return copyFile(path, target, info.Mode())
		}
	})
}

func copyFile(src, dest string, mode fs.FileMode) error {
	in, err := os.Open(src)
	if err != nil {
		return err
	}
	defer in.Close()

	out, err := os.OpenFile(dest, os.O_CREATE|os.O_WRONLY|os.O_TRUNC, mode)
	if err != nil {
		return err
	}
	defer func() {
		_ = out.Close()
	}()

	if _, err := io.Copy(out, in); err != nil {
		return err
	}
	return nil
}

func getenvDefault(k, def string) string {
	if v := os.Getenv(k); v != "" {
		return v
	}
	return def
}

func must(err error) {
	if err != nil {
		log.Fatal(err)
	}
}
