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

/*
次のディレクトリが存在する
- worktree 用
  - /Users/Komatsu.Aya/ghq/github.com/hrbrain/hrbrain/hrbrain.worktrees

- worktree に対応する　VSCode のワークスペース用設定ファイルの配置場所
  - /Users/Komatsu.Aya/ghq/github.com/hrbrain/hrbrain/code-workspaces

newには2つの引数が与えられる
new ブランチ名 統合ブランチ名
e.g. new PER-7332 main

すると次のコマンドが実行され  code-workspaces が追加される

cd /Users/Komatsu.Aya/ghq/github.com/hrbrain/hrbrain/
git worktree add -b PER-7332 ../hrbrain.worktrees/main-PER-7332 origin/PER-7332
*/
var newCmd = &cobra.Command{
	Use:   "new <branch-name> <base-branch-name>",
	Short: "Create a git worktree and open a workspace for it",
	Args:  cobra.ExactArgs(2), // 2つの引数 (ブランチ名と統合ブランチ名) を期待するように変更
	RunE: func(cmd *cobra.Command, args []string) error {
		branchName := args[0]
		baseBranchName := args[1] // 統合ブランチ名を追加

		homeDir, err := os.UserHomeDir()
		if err != nil {
			return fmt.Errorf("failed to get home directory: %w", err)
		}
		basePath := filepath.Join(homeDir, "ghq/github.com/hrbrain")
		repoRoot := filepath.Join(basePath, "hrbrain") // リポジトリのルートパス

		// git worktree add コマンド実行前に、worktree のパスを決定
		// 例: ../hrbrain.worktrees/main-PER-7332
		worktreeRelativePath := filepath.Join("..", "hrbrain.worktrees", fmt.Sprintf("%s-%s", baseBranchName, branchName))
		gitWorktreeFullPath := filepath.Join(repoRoot, worktreeRelativePath) // git worktree add に渡す絶対パス

		fmt.Printf("ℹ️  Checking if worktree path already exists: %s\n", gitWorktreeFullPath)
		if _, err := os.Stat(gitWorktreeFullPath); !os.IsNotExist(err) {
			return fmt.Errorf("❌ Worktree path already exists: %s. Please remove it first or choose a different name.", gitWorktreeFullPath)
		}

		// 対象ブランチがメインリポジトリにローカルに存在するかどうかを判断
		branchExistsLocallyCmd := exec.Command("git", "show-ref", "--verify", "--quiet", fmt.Sprintf("refs/heads/%s", branchName))
		branchExistsLocallyCmd.Dir = repoRoot
		err = branchExistsLocallyCmd.Run() // 出力は不要、終了コードのみ
		branchExistsLocally := err == nil  // errがnilの場合、コマンドは成功し、ブランチが存在する

		var worktreeAddArgs []string
		if branchExistsLocally {
			fmt.Printf("ℹ️  Local branch '%s' already exists. Adding worktree to checkout existing branch.\n", branchName)
			// ブランチがローカルに存在する場合、-b を使用せずに直接チェックアウト
			worktreeAddArgs = []string{"worktree", "add", gitWorktreeFullPath, branchName}
		} else {
			fmt.Printf("ℹ️  Local branch '%s' does not exist. Creating new branch and adding worktree from origin/%s.\n", branchName, branchName)
			// ブランチがローカルに存在しない場合、新しいブランチを作成し、originに基づいてワークツリーを追加
			worktreeAddArgs = []string{"worktree", "add", "-b", branchName, gitWorktreeFullPath, fmt.Sprintf("origin/%s", branchName)}
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

		// NewCodeWorkSpace に渡す worktreeName は結合された名前
		workspaceWorktreeName := fmt.Sprintf("%s-%s", baseBranchName, branchName)
		workspaceFile, _, err := NewCodeWorkSpace(workspaceWorktreeName, basePath) // worktreePath は NewCodeWorkSpace 内部で構築されるため、ここでは不要
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
