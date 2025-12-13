package cmd

import (
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"

	"github.com/spf13/cobra"
)

// 仕様
// baseブランチは、リモートになければローカルを参照する
var (
	copyDB    bool
	remoteURL string
)

//
// ===== パス/リポ基礎ユーティリティ =====
//

// 親リポの場所
func repoRootPath(homeDir string) string {
	return filepath.Join(homeDir, "wt/github.com/hrbrain/hrbrain")
}

// ワークツリー基底
func worktreesRoot(homeDir string) string {
	return filepath.Join(repoRootPath(homeDir), "worktrees")
}

// Git リポかどうか
func isGitRepo(path string) bool {
	if fi, err := os.Stat(filepath.Join(path, ".git")); err == nil && fi.IsDir() {
		return true
	}
	cmd := exec.Command("git", "-C", path, "rev-parse", "--git-dir")
	if err := cmd.Run(); err == nil {
		return true
	}
	return false
}

// 先頭スラッシュが欠けている場合に補う（mac/Linux 用）
func ensureAbsolute(p string) string {
	if p == "" {
		return p
	}
	if filepath.IsAbs(p) {
		return p
	}
	if runtime.GOOS == "windows" {
		return p
	}
	return string(os.PathSeparator) + p
}

// ghq から正確なフルパスを取得（無ければ $HOME/ghq/... をフォールバック）
func detectGhqRepoPath() (string, error) {
	// 1) ghq が使えるなら最優先
	if _, err := exec.LookPath("ghq"); err == nil {
		out, err := exec.Command("ghq", "list", "-p", "github.com/hrbrain/hrbrain").Output()
		if err == nil {
			p := strings.TrimSpace(string(out))
			if p != "" {
				return filepath.Clean(p), nil
			}
		}
	}
	// 2) フォールバック
	home, _ := os.UserHomeDir()
	return filepath.Clean(filepath.Join(home, "ghq/github.com/hrbrain/hrbrain")), nil
}

// パスが github.com/hrbrain で止まっていれば hrbrain を付与して .git を検証
func fixHrbrainRepoPath(p string) (string, error) {
	p = filepath.Clean(p)
	// すでに repo 直下なら OK
	if isGitRepo(p) {
		return p, nil
	}
	// 末尾が github.com/hrbrain で止まっている？ → /hrbrain を試す
	if strings.HasSuffix(p, filepath.Join("github.com", "hrbrain")) {
		cand := filepath.Join(p, "hrbrain")
		if isGitRepo(cand) {
			return cand, nil
		}
	}
	// それでもダメならそのまま返す（以降のコピーはスキップ運用）
	return p, fmt.Errorf("repo root does not contain .git: %s", p)
}

//
// ===== 親リポを保証（clone/fetch） =====
//

func safeClone(remote, dst string) error {
	if err := os.MkdirAll(filepath.Dir(dst), 0o755); err != nil {
		return fmt.Errorf("failed to create repo root parent: %w", err)
	}
	fmt.Printf("ℹ️  Cloning %s into %s\n", remote, dst)
	clone := exec.Command("git", "clone", "--origin", "origin", remote, dst)
	clone.Stdout, clone.Stderr = os.Stdout, os.Stderr
	return clone.Run()
}

func ensureRepoRoot(repoRoot, fallbackRemote string) error {
	_, statErr := os.Stat(repoRoot)
	switch {
	case errors.Is(statErr, os.ErrNotExist):
		if fallbackRemote == "" {
			fallbackRemote = "git@github.com:hrbrain/hrbrain.git"
		}
		return safeClone(fallbackRemote, repoRoot)

	case statErr == nil:
		if !isGitRepo(repoRoot) {
			fmt.Printf("⚠️  %s exists but is not a git repo. Reinitializing...\n", repoRoot)
			if err := os.RemoveAll(repoRoot); err != nil {
				return fmt.Errorf("failed to remove non-git dir: %w", err)
			}
			if fallbackRemote == "" {
				fallbackRemote = "git@github.com:hrbrain/hrbrain.git"
			}
			return safeClone(fallbackRemote, repoRoot)
		}
		fmt.Println("ℹ️  Fetching latest refs...")
		fetch := exec.Command("git", "-C", repoRoot, "fetch", "--all", "--prune")
		fetch.Stdout, fetch.Stderr = os.Stdout, os.Stderr
		_ = fetch.Run()
		return nil

	default:
		return fmt.Errorf("failed to stat repo root: %w", statErr)
	}
}

//
// ===== ws new コマンド本体 =====
//

var newCmd = &cobra.Command{
	Use:   "new <base-branch-name> <branch-name> [comment]",
	Short: "Create a git worktree and open a workspace for it",
	Args:  cobra.RangeArgs(2, 10),
	RunE: func(cmd *cobra.Command, args []string) error {
		baseBranchName := args[0]
		branchName := args[1]
		comment := ""
		if len(args) > 2 {
			comment = strings.Join(args[2:], " ")
		}

		homeDir, err := os.UserHomeDir()
		if err != nil {
			return fmt.Errorf("failed to get home directory: %w", err)
		}

		repoRoot := repoRootPath(homeDir)
		wtRoot := worktreesRoot(homeDir)

		// 親リポ保障
		if err := ensureRepoRoot(repoRoot, remoteURL); err != nil {
			return fmt.Errorf("failed to ensure repo root: %w", err)
		}

		// WT基底作成
		if err := os.MkdirAll(wtRoot, 0o755); err != nil {
			return fmt.Errorf("failed to create worktrees root dir: %w", err)
		}

		// worktree ディレクトリ名
		var worktreeName string
		if comment == "" {
			worktreeName = fmt.Sprintf("%s-%s", baseBranchName, branchName)
		} else {
			worktreeName = fmt.Sprintf("%s-%s-%s", baseBranchName, branchName, comment)
		}
		gitWorktreeFullPath := filepath.Join(wtRoot, worktreeName)

		// 既存チェック
		fmt.Printf("ℹ️  Checking if worktree path already exists: %s\n", gitWorktreeFullPath)
		if _, err := os.Stat(gitWorktreeFullPath); !os.IsNotExist(err) {
			return fmt.Errorf("❌ Worktree path already exists: %s", gitWorktreeFullPath)
		}

		// --- ブランチが他のワークツリーで使用されているかチェック ---
		wtListCmd := exec.Command("git", "worktree", "list", "--porcelain")
		wtListCmd.Dir = repoRoot
		wtListOut, err := wtListCmd.Output()
		if err == nil {
			lines := strings.Split(string(wtListOut), "\n")
			var currentWorktreePath string
			for _, line := range lines {
				if strings.HasPrefix(line, "worktree ") {
					currentWorktreePath = strings.TrimPrefix(line, "worktree ")
				}
				if strings.HasPrefix(line, "branch refs/heads/"+branchName) {
					return fmt.Errorf("❌ Branch '%s' is already used by worktree at '%s'\n💡 Hint: Use a different branch name or remove the existing worktree first with:\n   git worktree remove %s", branchName, currentWorktreePath, currentWorktreePath)
				}
			}
		}

		// --- ブランチ存在確認 ---
		branchExistsLocallyCmd := exec.Command("git", "show-ref", "--verify", "--quiet", fmt.Sprintf("refs/heads/%s", branchName))
		branchExistsLocallyCmd.Dir = repoRoot
		err = branchExistsLocallyCmd.Run()
		branchExistsLocally := err == nil

		remoteExistsCmd := exec.Command("git", "show-ref", "--verify", "--quiet", fmt.Sprintf("refs/remotes/origin/%s", branchName))
		remoteExistsCmd.Dir = repoRoot
		err = remoteExistsCmd.Run()
		remoteExists := err == nil

		baseLocalCmd := exec.Command("git", "show-ref", "--verify", "--quiet", fmt.Sprintf("refs/heads/%s", baseBranchName))
		baseLocalCmd.Dir = repoRoot
		err = baseLocalCmd.Run()
		baseExistsLocally := err == nil

		baseRemoteCmd := exec.Command("git", "show-ref", "--verify", "--quiet", fmt.Sprintf("refs/remotes/origin/%s", baseBranchName))
		baseRemoteCmd.Dir = repoRoot
		err = baseRemoteCmd.Run()
		baseExistsRemotely := err == nil

		// worktree add 引数
		var worktreeAddArgs []string
		switch {
		case branchExistsLocally:
			fmt.Printf("ℹ️  Using existing local branch '%s'\n", branchName)
			worktreeAddArgs = []string{"worktree", "add", gitWorktreeFullPath, branchName}
		case remoteExists:
			fmt.Printf("ℹ️  Creating local '%s' from origin/%s\n", branchName, branchName)
			worktreeAddArgs = []string{"worktree", "add", "-b", branchName, gitWorktreeFullPath, fmt.Sprintf("origin/%s", branchName)}
		default:
			var baseRef string
			switch {
			case baseExistsLocally:
				baseRef = baseBranchName
			case baseExistsRemotely:
				baseRef = fmt.Sprintf("origin/%s", baseBranchName)
			default:
				return fmt.Errorf("❌ base branch '%s' not found locally nor on origin", baseBranchName)
			}
			fmt.Printf("ℹ️  Creating '%s' from '%s'\n", branchName, baseRef)
			worktreeAddArgs = []string{"worktree", "add", "-b", branchName, gitWorktreeFullPath, baseRef}
		}

		// 実行
		fmt.Printf("ℹ️  Executing git %s (in %s)...\n", strings.Join(worktreeAddArgs, " "), repoRoot)
		worktreeAddCmd := exec.Command("git", worktreeAddArgs...)
		worktreeAddCmd.Dir = repoRoot
		worktreeAddCmd.Stdout = os.Stdout
		worktreeAddCmd.Stderr = os.Stderr
		if err := worktreeAddCmd.Run(); err != nil {
			return fmt.Errorf("❌ Failed to execute 'git %s': %w", strings.Join(worktreeAddArgs, " "), err)
		}
		fmt.Printf("✅ Git worktree '%s' added at %s\n", branchName, gitWorktreeFullPath)

		// ====== launch.json 作成 (常に実行) ======
		persiaAppPath := filepath.Join(gitWorktreeFullPath, "apps/persia/app")
		fmt.Printf("ℹ️  Creating launch.json for worktree: %s\n", worktreeName)
		if err := createLaunchJSON(persiaAppPath, wtRoot, worktreeName); err != nil {
			fmt.Printf("⚠️  Failed to create launch.json: %v\n", err)
		}

		// ====== DB/設定コピー ======
		if copyDB {
			ghqRoot, _ := detectGhqRepoPath() // ghq で実パス取得
			ghqRoot = ensureAbsolute(ghqRoot) // 先頭スラッシュ矯正
			// github.com/hrbrain で止まってたら hrbrain を付与
			if fixed, err := fixHrbrainRepoPath(ghqRoot); err == nil {
				ghqRoot = fixed
			}
			fmt.Printf("ℹ️  Copying database and configuration files from: %s\n", ghqRoot)

			if err := copyDatabaseAndConfig(gitWorktreeFullPath, ghqRoot, wtRoot); err != nil {
				return fmt.Errorf("❌ Failed to copy database and config files: %w", err)
			}
			fmt.Println("✅ Database and configuration files copied successfully")
		}

		// VSCode ワークスペース作成
		workspaceFile, _, err := NewCodeWorkSpace(worktreeName, wtRoot)
		if err != nil {
			return err
		}
		fmt.Printf("✅ Workspace created: %s\n", workspaceFile)

		// VSCode 起動
		fmt.Printf("ℹ️  Opening VSCode: %s\n", workspaceFile)
		if err := exec.Command("code", workspaceFile).Start(); err != nil {
			fmt.Printf("❌ Failed to open VSCode: %v\n", err)
			os.Exit(1)
		}

		// mise trust
		fmt.Printf("ℹ️  Running 'mise trust' in %s\n", gitWorktreeFullPath)
		miseCmd := exec.Command("mise", "trust", gitWorktreeFullPath)
		miseCmd.Stdout, miseCmd.Stderr = os.Stdout, os.Stderr
		if err := miseCmd.Run(); err != nil {
			fmt.Printf("❌ Failed to execute 'mise trust': %v\n", err)
			os.Exit(1)
		}
		fmt.Println("✅ 'mise trust' executed.")

		fmt.Printf("🚀 Run: %s\n", worktreeName)
		return nil
	},
}

//
// ===== VSCode Workspace =====
//

func NewCodeWorkSpace(worktreeName string, wtRoot string) (string, string, error) {
	worktreePath := filepath.Join(wtRoot, worktreeName)
	if _, err := os.Stat(worktreePath); os.IsNotExist(err) {
		return "", "", fmt.Errorf("❌ Worktree path does not exist: %s", worktreePath)
	}

	workspaceDir := filepath.Join(wtRoot, "code-workspaces")
	workspaceFile := filepath.Join(workspaceDir, worktreeName+".code-workspace")
	if err := os.MkdirAll(workspaceDir, 0o755); err != nil {
		return "", "", fmt.Errorf("failed to create workspace directory: %w", err)
	}

	workspace := map[string][]map[string]string{
		"folders": {
			{"path": filepath.Join(worktreePath, "apps/persia/app")},
			{"path": filepath.Join(worktreePath, "apps/persia/front")},
			{"path": filepath.Join(worktreePath, "apps/persia/schema")},
		},
	}

	file, err := os.Create(workspaceFile)
	if err != nil {
		return "", "", fmt.Errorf("failed to create workspace file: %w", err)
	}
	defer file.Close()

	encoder := json.NewEncoder(file)
	encoder.SetIndent("", "  ")
	if err := encoder.Encode(workspace); err != nil {
		return "", "", fmt.Errorf("failed to write workspace JSON: %w", err)
	}

	return workspaceFile, worktreePath, nil
}

func init() {
	newCmd.Flags().BoolVar(&copyDB, "copy-db", false, "Copy database and configuration files when creating worktree")
	newCmd.Flags().StringVar(&remoteURL, "remote", "", "Git remote URL to clone when repo root is missing (default: git@github.com:hrbrain/hrbrain.git)")
}

//
// ===== コピー関連 =====
//

func copyDatabaseAndConfig(gitWorktreeFullPath, sourceRoot, wtRoot string) error {
	workspaceWorktreeName := filepath.Base(gitWorktreeFullPath)
	worktreesRoot := filepath.Join(wtRoot)

	// 宛先パス
	bengalAppPath := filepath.Join(worktreesRoot, workspaceWorktreeName, "apps/bengal/app")
	persiaAppPath := filepath.Join(worktreesRoot, workspaceWorktreeName, "apps/persia/app")
	persiaFrontPath := filepath.Join(worktreesRoot, workspaceWorktreeName, "apps/persia/front")
	tiltPath := filepath.Join(worktreesRoot, workspaceWorktreeName, "tilt")

	// .data ディレクトリ
	fmt.Printf("ℹ️  Copying .data directories to worktree: %s\n", workspaceWorktreeName)
	_ = copyDirIfExists(filepath.Join(sourceRoot, "apps/bengal/app/.data"), filepath.Join(bengalAppPath, ".data"))
	_ = copyDirIfExists(filepath.Join(sourceRoot, "apps/persia/app/.data"), filepath.Join(persiaAppPath, ".data"))

	// 設定ファイル
	fmt.Printf("ℹ️  Copying configuration files to worktree: %s\n", workspaceWorktreeName)
	_ = copyFileIfExists(filepath.Join(sourceRoot, "tilt/tilt_config.json"), filepath.Join(tiltPath, "tilt_config.json"))
	_ = copyFileIfExists(filepath.Join(sourceRoot, "apps/persia/app/.env"), filepath.Join(persiaAppPath, ".env"))
	_ = copyFileIfExists(filepath.Join(sourceRoot, "apps/persia/front/.env.local"), filepath.Join(persiaFrontPath, ".env.local"))

	fmt.Println("✅ Copied DB and config (missing sources were skipped with warnings)")
	return nil
}

func copyFileIfExists(src, dst string) error {
	src = filepath.Clean(src)
	dst = filepath.Clean(dst)
	if _, err := os.Stat(src); os.IsNotExist(err) {
		fmt.Printf("⚠️  skip: file not found: %s\n", src)
		return nil
	}
	if err := os.MkdirAll(filepath.Dir(dst), 0o755); err != nil {
		return err
	}
	fmt.Printf("ℹ️  copying file: %s -> %s\n", src, dst)
	cmd := exec.Command("cp", src, dst)
	cmd.Stdout, cmd.Stderr = os.Stdout, os.Stderr
	if err := cmd.Run(); err != nil {
		fmt.Printf("⚠️  copy failed but continuing: %v\n", err)
		return nil
	}
	return nil
}

func copyDirIfExists(src, dst string) error {
	src = filepath.Clean(src)
	dst = filepath.Clean(dst)
	if _, err := os.Stat(src); os.IsNotExist(err) {
		fmt.Printf("⚠️  skip: dir not found: %s\n", src)
		return nil
	}
	if err := os.MkdirAll(filepath.Dir(dst), 0o755); err != nil {
		return err
	}
	fmt.Printf("ℹ️  copying directory: %s -> %s\n", src, dst)
	cmd := exec.Command("cp", "-r", src, dst)
	cmd.Stdout, cmd.Stderr = os.Stdout, os.Stderr
	if err := cmd.Run(); err != nil {
		fmt.Printf("⚠️  copy failed but continuing: %v\n", err)
		return nil
	}
	return nil
}

func createLaunchJSON(persiaAppPath, worktreesRoot, workspaceWorktreeName string) error {
	vscodeDir := filepath.Join(persiaAppPath, ".vscode")
	if err := os.MkdirAll(vscodeDir, 0o755); err != nil {
		return fmt.Errorf("failed to create .vscode directory: %w", err)
	}

	launchJSONPath := filepath.Join(vscodeDir, "launch.json")

	// 既存ファイルがあれば削除
	if _, err := os.Stat(launchJSONPath); err == nil {
		fmt.Printf("ℹ️  Existing launch.json found, overwriting: %s\n", launchJSONPath)
		if err := os.Remove(launchJSONPath); err != nil {
			return fmt.Errorf("failed to remove existing launch.json: %w", err)
		}
	}

	worktreeFullPath := filepath.Join(worktreesRoot, workspaceWorktreeName)

	launchConfig := map[string]interface{}{
		"version": "0.2.0",
		"configurations": []map[string]interface{}{
			{
				"name":         "Remote (if the path where the hrbrain repository is located is different from the above)",
				"type":         "go",
				"request":      "attach",
				"mode":         "remote",
				"port":         14800,
				"host":         "localhost",
				"cwd":          "${workspaceRoot}",
				"showLog":      true,
				"debugAdapter": "dlv-dap",
				"substitutePath": []map[string]string{
					{
						"from": "${workspaceFolder}",
						"to":   filepath.Join(worktreeFullPath, "apps/persia/app"),
					},
					{
						"from": "${workspaceFolder}/../../../libs/hrbx",
						"to":   filepath.Join(worktreeFullPath, "libs/hrbx"),
					},
					{
						"from": "${workspaceFolder}/../../../libs/hrbx/log/v3",
						"to":   filepath.Join(worktreeFullPath, "libs/hrbx/log/v3"),
					},
					{
						"from": "${workspaceFolder}/../../../libs/hrbx/log/v3/adapters/grpc",
						"to":   filepath.Join(worktreeFullPath, "libs/hrbx/log/v3/adapters/grpc"),
					},
					{
						"from": "${workspaceFolder}/../../../libs/hrbx/otel",
						"to":   filepath.Join(worktreeFullPath, "libs/hrbx/otel"),
					},
					{
						"from": "${env:GOPATH}",
						"to":   "${env:HOME}/go",
					},
				},
			},
		},
	}

	file, err := os.Create(launchJSONPath)
	if err != nil {
		return fmt.Errorf("failed to create launch.json: %w", err)
	}
	defer file.Close()

	encoder := json.NewEncoder(file)
	encoder.SetIndent("", "  ")
	if err := encoder.Encode(launchConfig); err != nil {
		return fmt.Errorf("failed to write launch.json: %w", err)
	}

	fmt.Printf("✅ Created launch.json at %s\n", launchJSONPath)
	return nil
}
