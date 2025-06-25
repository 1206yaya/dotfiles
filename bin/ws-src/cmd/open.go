package cmd

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"

	"github.com/spf13/cobra"
)

var openCmd = &cobra.Command{
	Use:   "open <worktree-name>",
	Short: "Open the existing code-workspace in VSCode",
	Args:  cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
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
