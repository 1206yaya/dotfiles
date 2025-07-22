// Package cmd provides command implementations for the ws tool
package cmd

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"

	"github.com/spf13/cobra"
)

var rmCmd = &cobra.Command{
	Use:   "rm",
	Short: "Remove git worktrees",
	RunE: func(cmd *cobra.Command, args []string) error {
		allFlag, _ := cmd.Flags().GetBool("all")

		if !allFlag {
			return fmt.Errorf("❌ Please specify -a or --all flag-s to remove all worktrees")
		}

		homeDir, err := os.UserHomeDir()
		if err != nil {
			return fmt.Errorf("failed to get home directory: %w", err)
		}

		basePath := filepath.Join(homeDir, "ghq/github.com/hrbrain")
		repoRoot := filepath.Join(basePath, "hrbrain")
		worktreesPath := filepath.Join(basePath, "hrbrain.worktrees")

		// worktreesディレクトリが存在するかチェック
		if _, err := os.Stat(worktreesPath); os.IsNotExist(err) {
			fmt.Printf("ℹ️  Worktrees directory does not exist: %s\n", worktreesPath)
			return nil
		}

		fmt.Printf("⚠️  This will remove all worktrees in: %s\n", worktreesPath)
		fmt.Print("Are you sure? (y/N): ")

		var response string
		fmt.Scanln(&response)
		if response != "y" && response != "Y" {
			fmt.Println("❌ Operation cancelled")
			return nil
		}

		// worktreesディレクトリの中身を削除
		fmt.Printf("ℹ️  Removing all worktrees from: %s\n", worktreesPath)

		// ディレクトリの中身をすべて読み取って削除
		entries, err := os.ReadDir(worktreesPath)
		if err != nil {
			return fmt.Errorf("❌ Failed to read worktrees directory: %w", err)
		}

		for _, entry := range entries {
			entryPath := filepath.Join(worktreesPath, entry.Name())
			fmt.Printf("ℹ️  Removing: %s\n", entryPath)
			if err := os.RemoveAll(entryPath); err != nil {
				fmt.Printf("❌ Failed to remove %s: %v\n", entryPath, err)
				// エラーが発生しても他のディレクトリの削除は続行
			}
		}

		// git worktree prune を実行
		fmt.Println("ℹ️  Running 'git worktree prune'...")
		pruneCmd := exec.Command("git", "worktree", "prune")
		pruneCmd.Dir = repoRoot
		pruneCmd.Stdout = os.Stdout
		pruneCmd.Stderr = os.Stderr

		if err := pruneCmd.Run(); err != nil {
			return fmt.Errorf("❌ Failed to prune worktrees: %w", err)
		}

		// git worktree list で確認
		fmt.Println("ℹ️  Current worktree list:")
		listCmd := exec.Command("git", "worktree", "list")
		listCmd.Dir = repoRoot
		listCmd.Stdout = os.Stdout
		listCmd.Stderr = os.Stderr

		if err := listCmd.Run(); err != nil {
			return fmt.Errorf("❌ Failed to list worktrees: %w", err)
		}

		fmt.Println("✅ All worktrees removed successfully")
		return nil
	},
}

func init() {
	rmCmd.Flags().BoolP("all", "a", false, "Remove all worktrees")
}
