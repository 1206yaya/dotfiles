package cmd

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"

	"github.com/spf13/cobra"
)

var openCmd = &cobra.Command{
	Use:   "open [worktree-name]", // Make the argument optional
	Short: "Open the existing code-workspace in VSCode or list worktrees",
	Args:  cobra.MaximumNArgs(1), // Allow 0 or 1 argument
	RunE: func(cmd *cobra.Command, args []string) error {
		if len(args) == 0 {
			// No argument provided, execute the desired commands
			targetDir := "/Users/Komatsu.Aya/ghq/github.com/hrbrain/hrbrain"

			fmt.Printf("📂 Changing directory to: %s\n", targetDir)
			if err := os.Chdir(targetDir); err != nil {
				return fmt.Errorf("❌ Failed to change directory to %s: %w", targetDir, err)
			}

			fmt.Println("🌳 Listing git worktrees:")
			gitWorktreeListCmd := exec.Command("git", "worktree", "list")
			gitWorktreeListCmd.Stdout = os.Stdout
			gitWorktreeListCmd.Stderr = os.Stderr
			if err := gitWorktreeListCmd.Run(); err != nil {
				return fmt.Errorf("❌ Failed to execute 'git worktree list': %w", err)
			}
			return nil
		}

		// Argument provided, proceed with opening VSCode
		worktreeName := args[0]

		homeDir, err := os.UserHomeDir()
		if err != nil {
			return fmt.Errorf("failed to get home directory: %w", err)
		}

		workspaceFile := filepath.Join(
			homeDir,
			"ghq/github.com/hrbrain/code-workspaces",
			worktreeName+".code-workspace",
		)

		if _, err := os.Stat(workspaceFile); os.IsNotExist(err) {
			return fmt.Errorf("❌ Workspace file does not exist: %s", workspaceFile)
		}

		fmt.Printf("🚀 Opening VSCode with: %s\n", workspaceFile)
		if err := exec.Command("code", workspaceFile).Start(); err != nil {
			return fmt.Errorf("❌ Failed to open VSCode: %w", err)
		}

		return nil
	},
}
