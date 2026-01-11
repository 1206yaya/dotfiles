package cmd

// import (
// 	"context"
// 	"errors"
// 	"fmt"
// 	"net/url"
// 	"os"
// 	"os/exec"
// 	"path/filepath"
// 	"regexp"
// 	"strings"

// 	"github.com/google/go-github/v61/github"
// 	"github.com/spf13/cobra"
// 	"golang.org/x/oauth2"
// )

// var (
// 	flagRepo         string // owner/repo（未指定なら git remote から推測）
// 	flagWorktreesDir string // worktree の作成先（デフォルト: ..）
// 	flagRemote       string // fetch 先 remote（デフォルト: origin）
// 	flagDryRun       bool
// )

// func main() {
// 	root := &cobra.Command{
// 		Use:   "mytool",
// 		Short: "Dev utility CLI",
// 	}

// 	checkoutCmd := &cobra.Command{
// 		Use:   "checkout <PR_NUMBER>",
// 		Short: "Create a git worktree from a GitHub PR number",
// 		Args:  cobra.ExactArgs(1),
// 		RunE:  runCheckout,
// 	}

// 	checkoutCmd.Flags().StringVar(&flagRepo, "repo", "", "GitHub repository in 'owner/name' (optional)")
// 	checkoutCmd.Flags().StringVar(&flagWorktreesDir, "worktrees-dir", "..", "Directory to create worktrees in")
// 	checkoutCmd.Flags().StringVar(&flagRemote, "remote", "origin", "Git remote name to fetch from")
// 	checkoutCmd.Flags().BoolVar(&flagDryRun, "dry-run", false, "Print actions without executing")

// 	root.AddCommand(checkoutCmd)

// 	if err := root.Execute(); err != nil {
// 		os.Exit(1)
// 	}
// }

// func runCheckout(cmd *cobra.Command, args []string) error {
// 	// 1) 入力: PR番号
// 	prNum, err := parseInt(args[0])
// 	if err != nil {
// 		return fmt.Errorf("invalid PR number: %w", err)
// 	}

// 	// 2) リポジトリ owner/name を決定
// 	owner, repo, err := resolveOwnerRepo(flagRepo)
// 	if err != nil {
// 		return err
// 	}

// 	// 3) GitHub API クライアント
// 	ctx := context.Background()
// 	gh, err := ghClient(ctx)
// 	if err != nil {
// 		return err
// 	}

// 	// 4) PR 情報取得
// 	pr, _, err := gh.PullRequests.Get(ctx, owner, repo, prNum)
// 	if err != nil {
// 		return fmt.Errorf("failed to get PR: %w", err)
// 	}
// 	if pr.Head == nil || pr.Head.Ref == nil {
// 		return errors.New("PR head ref not found")
// 	}
// 	branch := *pr.Head.Ref

// 	// 5) 作成先パス
// 	worktreesDir := flagWorktreesDir
// 	if worktreesDir == "" {
// 		worktreesDir = ".."
// 	}
// 	absDir, err := filepath.Abs(worktreesDir)
// 	if err != nil {
// 		return err
// 	}
// 	dest := filepath.Join(absDir, branch)

// 	fmt.Printf("PR   : #%d (%s/%s)\n", prNum, owner, repo)
// 	fmt.Printf("Branch: %s\n", branch)
// 	fmt.Printf("Dir   : %s\n", dest)
// 	fmt.Printf("Remote: %s\n", flagRemote)

// 	if flagDryRun {
// 		return nil
// 	}

// 	// 6) git fetch pull/<num>/head:<branch>
// 	if err := run("git", "fetch", flagRemote, fmt.Sprintf("pull/%d/head:%s", prNum, branch)); err != nil {
// 		// 既にローカルにブランチがある場合はスキップ許容
// 		if !strings.Contains(err.Error(), "updates were rejected") &&
// 			!strings.Contains(err.Error(), "set-upstream") &&
// 			!strings.Contains(err.Error(), "already exists") {
// 			return fmt.Errorf("git fetch failed: %w", err)
// 		}
// 	}

// 	// 7) git worktree add -b <branch> <dest> <branch>
// 	if pathExists(dest) {
// 		return fmt.Errorf("destination already exists: %s", dest)
// 	}
// 	if err := run("git", "worktree", "add", "-b", branch, dest, branch); err != nil {
// 		return fmt.Errorf("git worktree add failed: %w", err)
// 	}

// 	fmt.Printf("✅ Worktree created: %s\n", dest)
// 	return nil
// }

// func run(name string, args ...string) error {
// 	cmd := exec.Command(name, args...)
// 	cmd.Stdout = os.Stdout
// 	cmd.Stderr = os.Stderr
// 	return cmd.Run()
// }

// func parseInt(s string) (int, error) {
// 	re := regexp.MustCompile(`^\d+$`)
// 	if !re.MatchString(s) {
// 		return 0, fmt.Errorf("not a number: %s", s)
// 	}
// 	var n int
// 	_, err := fmt.Sscanf(s, "%d", &n)
// 	return n, err
// }

// func ghClient(ctx context.Context) (*github.Client, error) {
// 	token := os.Getenv("GITHUB_TOKEN")
// 	if token == "" {
// 		return nil, errors.New("GITHUB_TOKEN is not set")
// 	}
// 	ts := oauth2.StaticTokenSource(&oauth2.Token{AccessToken: token})
// 	tc := oauth2.NewClient(ctx, ts)
// 	return github.NewClient(tc), nil
// }

// func resolveOwnerRepo(repoFlag string) (string, string, error) {
// 	if repoFlag != "" {
// 		parts := strings.Split(repoFlag, "/")
// 		if len(parts) != 2 {
// 			return "", "", fmt.Errorf("--repo must be 'owner/name'")
// 		}
// 		return parts[0], parts[1], nil
// 	}
// 	// git remote から推測
// 	u, err := remoteURL("origin")
// 	if err != nil {
// 		return "", "", fmt.Errorf("cannot infer repo: %w", err)
// 	}
// 	owner, name, err := parseGitHubURL(u)
// 	if err != nil {
// 		return "", "", err
// 	}
// 	return owner, name, nil
// }

// func remoteURL(remote string) (string, error) {
// 	out, err := exec.Command("git", "config", "--get", "remote."+remote+".url").Output()
// 	if err != nil {
// 		return "", err
// 	}
// 	return strings.TrimSpace(string(out)), nil
// }

// func parseGitHubURL(u string) (string, string, error) {
// 	// https or ssh 両対応
// 	if strings.HasPrefix(u, "git@") {
// 		// git@github.com:owner/repo.git
// 		parts := strings.SplitN(u, ":", 2)
// 		if len(parts) != 2 {
// 			return "", "", fmt.Errorf("invalid ssh url: %s", u)
// 		}
// 		path := strings.TrimSuffix(parts[1], ".git")
// 		pp := strings.Split(path, "/")
// 		if len(pp) != 2 {
// 			return "", "", fmt.Errorf("invalid ssh path: %s", path)
// 		}
// 		return pp[0], pp[1], nil
// 	}
// 	pu, err := url.Parse(u)
// 	if err != nil {
// 		return "", "", err
// 	}
// 	path := strings.TrimPrefix(pu.Path, "/")
// 	path = strings.TrimSuffix(path, ".git")
// 	pp := strings.Split(path, "/")
// 	if len(pp) != 2 {
// 		return "", "", fmt.Errorf("invalid https path: %s", path)
// 	}
// 	return pp[0], pp[1], nil
// }

// func pathExists(p string) bool {
// 	_, err := os.Stat(p)
// 	return err == nil
// }
