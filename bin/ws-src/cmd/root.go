package cmd

import (
	"github.com/spf13/cobra"
)

var rootCmd = &cobra.Command{
	Use:   "ws",
	Short: "Worktree utility",
	Long:  `Worktree management CLI tool`,
}

func Execute() {
	cobra.CheckErr(rootCmd.Execute())
}

func init() {
	rootCmd.AddCommand(newCmd)
	rootCmd.AddCommand(openCmd)
}
