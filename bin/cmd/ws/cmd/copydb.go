package cmd

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"

	"github.com/spf13/cobra"
)

var copydbCmd = &cobra.Command{
	Use:   "copydb [workspace-worktree-name]",
	Short: "Copy database and configuration files to an existing worktree or list worktrees",
	Args:  cobra.MaximumNArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		homeDir, err := os.UserHomeDir()
		if err != nil {
			return fmt.Errorf("failed to get home directory: %w", err)
		}
		wtRoot := worktreesRoot(homeDir) // 新ルート: ~/wt/github.com/hrbrain/hrbrain/worktrees
		basePath := filepath.Join(homeDir, "ghq/github.com/hrbrain")

		// 引数なし → ワークツリー名の一覧
		if len(args) == 0 {
			worktreesDir := wtRoot

			fmt.Printf("📂 Available worktrees in: %s\n", worktreesDir)

			lsCmd := exec.Command("ls", worktreesDir)
			lsCmd.Stdout = os.Stdout
			lsCmd.Stderr = os.Stderr
			if err := lsCmd.Run(); err != nil {
				return fmt.Errorf("❌ Failed to list worktrees directory: %w", err)
			}
			return nil
		}

		// 引数あり → コピー実行
		workspaceWorktreeName := args[0]
		gitWorktreeFullPath := filepath.Join(wtRoot, workspaceWorktreeName)

		if _, err := os.Stat(gitWorktreeFullPath); os.IsNotExist(err) {
			return fmt.Errorf("❌ Worktree does not exist: %s", gitWorktreeFullPath)
		}

		fmt.Printf("ℹ️  Copying database and configuration files to worktree: %s\n", workspaceWorktreeName)
		if err := copyDatabaseAndConfig(gitWorktreeFullPath, basePath, wtRoot); err != nil {
			return fmt.Errorf("❌ Failed to copy database and config files: %w", err)
		}

		fmt.Println("✅ Database and configuration files copied successfully")
		return nil
	},
}
