package cmd

import (
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"

	"github.com/spf13/cobra"
)

var newCmd = &cobra.Command{
	Use:   "new <worktree-name>",
	Short: "Create and open a workspace for the specified worktree",
	Args:  cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		worktreeName := args[0]
		homeDir, err := os.UserHomeDir()
		if err != nil {
			return fmt.Errorf("failed to get home directory: %w", err)
		}

		basePath := filepath.Join(homeDir, "ghq/github.com/hrbrain")
		worktreePath := filepath.Join(basePath, "hrbrain.worktrees", worktreeName)

		if _, err := os.Stat(worktreePath); os.IsNotExist(err) {
			return fmt.Errorf("❌ Worktree path does not exist: %s", worktreePath)
		}

		workspaceDir := filepath.Join(basePath, "code-workspaces")
		workspaceFile := filepath.Join(workspaceDir, worktreeName+".code-workspace")

		if err := os.MkdirAll(workspaceDir, 0o755); err != nil {
			return fmt.Errorf("failed to create workspace directory: %w", err)
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
			return fmt.Errorf("failed to create workspace file: %w", err)
		}
		defer file.Close()

		encoder := json.NewEncoder(file)
		encoder.SetIndent("", "  ")
		if err := encoder.Encode(workspace); err != nil {
			return fmt.Errorf("failed to write workspace JSON: %w", err)
		}

		fmt.Printf("✅ Workspace created: %s\n", workspaceFile)

		// VSCode 起動
		if err := exec.Command("code", workspaceFile).Start(); err != nil {
			fmt.Printf("❌ Failed to open VSCode: %v\n", err)
			os.Exit(1)
		}
		return nil
	},
}
