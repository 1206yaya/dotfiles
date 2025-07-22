package cmd

import (
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/spf13/cobra"
)

var copyDB bool

/*
次のディレクトリが存在する
- worktree 用
  - /Users/Komatsu.Aya/ghq/github.com/hrbrain/hrbrain/hrbrain.worktrees

- worktree に対応する　VSCode のワークスペース用設定ファイルの配置場所
  - /Users/Komatsu.Aya/ghq/github.com/hrbrain/hrbrain/code-workspaces

第１引数は、統合ブランチ名を指定する
第２引数は、対象となるブランチ名を指定する
第3引数は、オプションで検索機能のような説明を追加する

e.g.
ws new main PER-7332 検索機能
ws new main PER-7332 検索機能 --copy-db  # データベースもコピー
git worktree add -b PER-7332 ../hrbrain.worktrees/main-PER-7332-検索機能 origin/PER-7332
*/
var newCmd = &cobra.Command{
	Use:   "new <base-branch-name> <branch-name> [comment]",
	Short: "Create a git worktree and open a workspace for it",
	Args:  cobra.RangeArgs(2, 10), // 2つ以上の引数を受け取る（コメント部分は複数の単語になる可能性があるため）
	RunE: func(cmd *cobra.Command, args []string) error {
		baseBranchName := args[0] // 統合ブランチ名を追加
		branchName := args[1]
		comment := ""
		if len(args) > 2 {
			comment = strings.Join(args[2:], " ") // 検索機能のような説明を追加
		}

		homeDir, err := os.UserHomeDir()
		if err != nil {
			return fmt.Errorf("failed to get home directory: %w", err)
		}
		basePath := filepath.Join(homeDir, "ghq/github.com/hrbrain")
		repoRoot := filepath.Join(basePath, "hrbrain") // リポジトリのルートパス

		// git worktree add コマンド実行前に、worktree のパスを決定
		// 例: ../hrbrain.worktrees/main-PER-7332
		worktreeRelativePath := filepath.Join("..", "hrbrain.worktrees", fmt.Sprintf("%s-%s-%s", baseBranchName, branchName, comment))
		gitWorktreeFullPath := filepath.Join(repoRoot, worktreeRelativePath) // git worktree add に渡す絶対パス

		fmt.Printf("ℹ️  Checking if worktree path already exists: %s\n", gitWorktreeFullPath)
		if _, err := os.Stat(gitWorktreeFullPath); !os.IsNotExist(err) {
			return fmt.Errorf("❌ Worktree path already exists: %s. Please remove it first or choose a different name", gitWorktreeFullPath)
		}

		// 対象ブランチがメインリポジトリにローカルに存在するかどうかを判断
		branchExistsLocallyCmd := exec.Command("git", "show-ref", "--verify", "--quiet", fmt.Sprintf("refs/heads/%s", branchName))
		branchExistsLocallyCmd.Dir = repoRoot
		err = branchExistsLocallyCmd.Run() // 出力は不要、終了コードのみ
		branchExistsLocally := err == nil  // errがnilの場合、コマンドは成功し、ブランチが存在する

		// リモートブランチが存在するかどうかを判断
		remoteExistsCmd := exec.Command("git", "show-ref", "--verify", "--quiet", fmt.Sprintf("refs/remotes/origin/%s", branchName))
		remoteExistsCmd.Dir = repoRoot
		err = remoteExistsCmd.Run()
		remoteExists := err == nil

		var worktreeAddArgs []string
		if branchExistsLocally {
			fmt.Printf("ℹ️  Local branch '%s' already exists. Adding worktree to checkout existing branch.\n", branchName)
			// ブランチがローカルに存在する場合、-b を使用せずに直接チェックアウト
			worktreeAddArgs = []string{"worktree", "add", gitWorktreeFullPath, branchName}
		} else if remoteExists {
			fmt.Printf("ℹ️  Local branch '%s' does not exist but remote branch exists. Creating new branch and adding worktree from origin/%s.\n", branchName, branchName)
			// ローカルブランチは存在しないが、リモートブランチが存在する場合
			worktreeAddArgs = []string{"worktree", "add", "-b", branchName, gitWorktreeFullPath, fmt.Sprintf("origin/%s", branchName)}
		} else {
			// ローカルブランチもリモートブランチも存在しない場合、baseBranchNameから新しいブランチを作成
			fmt.Printf("ℹ️  Neither local nor remote branch '%s' exists. Creating new branch from '%s'.\n", branchName, baseBranchName)
			worktreeAddArgs = []string{"worktree", "add", "-b", branchName, gitWorktreeFullPath, baseBranchName}
		}

		// git worktree add コマンドの構築と実行
		fmt.Printf("ℹ️  Executing git %s...\n", strings.Join(worktreeAddArgs, " ")) // デバッグ用
		worktreeAddCmd := exec.Command("git", worktreeAddArgs...)
		worktreeAddCmd.Dir = repoRoot // コマンドを実行するディレクトリ
		worktreeAddCmd.Stdout = os.Stdout
		worktreeAddCmd.Stderr = os.Stderr

		if err := worktreeAddCmd.Run(); err != nil {
			return fmt.Errorf("❌ Failed to execute 'git %s': %w", strings.Join(worktreeAddArgs, " "), err)
		}
		fmt.Printf("✅ Git worktree '%s' added successfully at %s\n", branchName, gitWorktreeFullPath)

		// データベースとファイルのコピー処理
		if copyDB {
			fmt.Println("ℹ️  Copying database and configuration files...")
			if err := copyDatabaseAndConfig(gitWorktreeFullPath, basePath); err != nil {
				return fmt.Errorf("❌ Failed to copy database and config files: %w", err)
			}
			fmt.Println("✅ Database and configuration files copied successfully")
		}

		// NewCodeWorkSpace に渡す worktreeName は結合された名前（コメント部分も含む）
		var workspaceWorktreeName string
		if comment == "" {
			workspaceWorktreeName = fmt.Sprintf("%s-%s", baseBranchName, branchName)
		} else {
			workspaceWorktreeName = fmt.Sprintf("%s-%s-%s", baseBranchName, branchName, comment)
		}
		workspaceFile, _, err := NewCodeWorkSpace(workspaceWorktreeName, basePath)
		if err != nil {
			return err
		}

		fmt.Printf("✅ Workspace created: %s\n", workspaceFile)

		// VSCode 起動
		fmt.Printf("ℹ️  Opening VSCode with workspace: %s\n", workspaceFile)
		if err := exec.Command("code", workspaceFile).Start(); err != nil {
			fmt.Printf("❌ Failed to open VSCode: %v\n", err)
			os.Exit(1)
		}

		// worktreePath で mise trust 実行
		fmt.Printf("ℹ️  Running 'mise trust' in worktree path: %s\n", gitWorktreeFullPath)
		miseCmd := exec.Command("mise", "trust", gitWorktreeFullPath)
		miseCmd.Stdout = os.Stdout
		miseCmd.Stderr = os.Stderr

		if err := miseCmd.Run(); err != nil {
			fmt.Printf("❌ Failed to execute 'mise trust': %v\n", err)
			os.Exit(1)
		}
		fmt.Println("✅ 'mise trust' executed successfully.")
		fmt.Printf("🚀 Run: %s\n", workspaceWorktreeName)

		// データベースと設定ファイルのコピー処理
		if copyDB {
			fmt.Printf("ℹ️  Copying database and configuration files to worktree path: %s\n", gitWorktreeFullPath)
			if err := copyDatabaseAndConfig(gitWorktreeFullPath, basePath); err != nil {
				return fmt.Errorf("❌ Failed to copy database and configuration files: %w", err)
			}
		}

		return nil
	},
}

// NewCodeWorkSpace は VS Code ワークスペースファイルを作成します。
func NewCodeWorkSpace(worktreeName string, basePath string) (string, string, error) {
	// worktreeName は 'baseBranchName-branchName' の形式を期待
	worktreePath := filepath.Join(basePath, "hrbrain.worktrees", worktreeName)
	if _, err := os.Stat(worktreePath); os.IsNotExist(err) {
		return "", "", fmt.Errorf("❌ Worktree path does not exist: %s", worktreePath)
	}

	workspaceDir := filepath.Join(basePath, "code-workspaces")
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
}

// copyDatabaseAndConfig は worktree にデータベースと設定ファイルをコピーします
func copyDatabaseAndConfig(gitWorktreeFullPath, basePath string) error {
	workspaceWorktreeName := filepath.Base(gitWorktreeFullPath)

	// パス定義
	hrbrainPath := basePath
	worktreePath := filepath.Join(basePath, "hrbrain.worktrees")

	bengalAppPath := filepath.Join(worktreePath, workspaceWorktreeName, "apps/bengal/app/")
	persiaAppPath := filepath.Join(worktreePath, workspaceWorktreeName, "apps/persia/app/")
	hachiAppPath := filepath.Join(worktreePath, workspaceWorktreeName, "apps/hachi/app/")
	persiaFrontPath := filepath.Join(worktreePath, workspaceWorktreeName, "apps/persia/front/")
	tiltPath := filepath.Join(worktreePath, workspaceWorktreeName, "tilt/")

	// .data ディレクトリのコピー
	if err := copyDir(filepath.Join(hrbrainPath, "hrbrain/apps/bengal/app/.data"), filepath.Join(bengalAppPath, ".data")); err != nil {
		return fmt.Errorf("failed to copy bengal .data: %w", err)
	}
	fmt.Println("✅ Copied bengal .data directory")

	if err := copyDir(filepath.Join(hrbrainPath, "hrbrain/apps/hachi/app/.data"), filepath.Join(hachiAppPath, ".data")); err != nil {
		return fmt.Errorf("failed to copy hachi .data: %w", err)
	}
	fmt.Println("✅ Copied hachi .data directory")

	if err := copyDir(filepath.Join(hrbrainPath, "hrbrain/apps/persia/app/.data"), filepath.Join(persiaAppPath, ".data")); err != nil {
		return fmt.Errorf("failed to copy persia .data: %w", err)
	}
	fmt.Println("✅ Copied persia .data directory")

	// 設定ファイルのコピー
	if err := copyFile(filepath.Join(hrbrainPath, "hrbrain/tilt/tilt_config.json"), filepath.Join(tiltPath, "tilt_config.json")); err != nil {
		return fmt.Errorf("failed to copy tilt_config.json: %w", err)
	}
	fmt.Println("✅ Copied tilt_config.json")

	if err := copyFile(filepath.Join(hrbrainPath, "hrbrain/apps/persia/app/.env"), filepath.Join(persiaAppPath, ".env")); err != nil {
		return fmt.Errorf("failed to copy persia app .env: %w", err)
	}
	fmt.Println("✅ Copied persia app .env")

	if err := copyFile(filepath.Join(hrbrainPath, "hrbrain/apps/persia/front/.env.local"), filepath.Join(persiaFrontPath, ".env.local")); err != nil {
		return fmt.Errorf("failed to copy persia front .env.local: %w", err)
	}
	fmt.Println("✅ Copied persia front .env.local")

	return nil
}

// copyFile はファイルをコピーします
func copyFile(src, dst string) error {
	cmd := exec.Command("cp", src, dst)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}

// copyDir はディレクトリを再帰的にコピーします
func copyDir(src, dst string) error {
	cmd := exec.Command("cp", "-r", src, dst)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}
