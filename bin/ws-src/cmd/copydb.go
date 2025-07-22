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
	Args:  cobra.MaximumNArgs(1), // Allow 0 or 1 argument
	RunE: func(cmd *cobra.Command, args []string) error {
		// 引数がない場合はワークツリーの一覧のworktreeNameだけを表示
		if len(args) == 0 {
			homeDir, err := os.UserHomeDir()
			if err != nil {
				return fmt.Errorf("failed to get home directory: %w", err)
			}
			worktreesDir := filepath.Join(homeDir, "ghq/github.com/hrbrain/hrbrain.worktrees")

			fmt.Printf("📂 Available worktrees in: %s\n", worktreesDir)

			// lsコマンドを実行してファイル名だけを表示
			lsCmd := exec.Command("ls", worktreesDir)
			lsCmd.Stdout = os.Stdout
			lsCmd.Stderr = os.Stderr
			if err := lsCmd.Run(); err != nil {
				return fmt.Errorf("❌ Failed to list worktrees directory: %w", err)
			}
			return nil
		}

		// Argument provided, proceed with copying database
		workspaceWorktreeName := args[0]

		homeDir, err := os.UserHomeDir()
		if err != nil {
			return fmt.Errorf("failed to get home directory: %w", err)
		}
		basePath := filepath.Join(homeDir, "ghq/github.com/hrbrain")

		// worktree のパスを構築
		gitWorktreeFullPath := filepath.Join(basePath, "hrbrain.worktrees", workspaceWorktreeName)

		// worktree が存在するかチェック
		if _, err := os.Stat(gitWorktreeFullPath); os.IsNotExist(err) {
			return fmt.Errorf("❌ Worktree does not exist: %s", gitWorktreeFullPath)
		}

		fmt.Printf("ℹ️  Copying database and configuration files to worktree: %s\n", workspaceWorktreeName)
		if err := copyDatabaseAndConfig(gitWorktreeFullPath, basePath); err != nil {
			return fmt.Errorf("❌ Failed to copy database and config files: %w", err)
		}

		fmt.Println("✅ Database and configuration files copied successfully")
		return nil
	},
}
