package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/joho/godotenv"
)

const (
	owner  = "hrbrain"
	repo   = "hrbrain"
	number = "36551"
)

type fileAdditions struct {
	Filename  string
	Additions []string
}

func main() {
	_ = godotenv.Load(".env")

	token := os.Getenv("GITHUB_TOKEN")
	if token == "" {
		fmt.Fprintln(os.Stderr, "error: GITHUB_TOKEN not set in .env or environment")
		os.Exit(1)
	}

	// まずは files API から取得（ファイル名を確実に取れる）
	files, err := fetchPRFiles(owner, repo, number, token)
	if err != nil || len(files) == 0 {
		// フォールバック: 生diff を解析
		diff, derr := fetchPRDiff(owner, repo, number, token)
		if derr != nil {
			fmt.Fprintln(os.Stderr, "error fetching files and diff:", err, derr)
			os.Exit(1)
		}
		files = parseUnifiedDiff(diff)
	}

	// Markdown 出力（Copilot に渡しやすい）
	var b strings.Builder
	b.WriteString("# Added lines by file\n\n")
	for _, f := range files {
		if len(f.Additions) == 0 {
			continue
		}
		b.WriteString("## " + f.Filename + "\n")
		b.WriteString("```diff\n")
		for _, line := range f.Additions {
			b.WriteString("+ " + line + "\n")
		}
		b.WriteString("```\n\n")
	}
	fmt.Print(b.String())
}

func fetchPRDiff(owner, repo, number, token string) (string, error) {
	api := fmt.Sprintf("https://api.github.com/repos/%s/%s/pulls/%s", owner, repo, number)

	req, err := http.NewRequest("GET", api, nil)
	if err != nil {
		return "", err
	}
	req.Header.Set("Accept", "application/vnd.github.v3.diff")
	req.Header.Set("User-Agent", "pr-additions-go")
	req.Header.Set("Authorization", "Bearer "+token)

	client := &http.Client{Timeout: 30 * time.Second}
	res, err := client.Do(req)
	if err != nil {
		return "", err
	}
	defer res.Body.Close()

	if res.StatusCode < 200 || res.StatusCode >= 300 {
		body, _ := io.ReadAll(io.LimitReader(res.Body, 2048))
		return "", fmt.Errorf("GitHub API %s: %s\n%s", api, res.Status, string(body))
	}
	diffBytes, err := io.ReadAll(res.Body)
	return string(diffBytes), err
}

// GitHub PR Files API のレスポンス用
type ghPRFile struct {
	Filename string `json:"filename"`
	Patch    string `json:"patch"`
	Status   string `json:"status"`
}

// PRに含まれる各ファイルの追加行を取得（ファイル名はAPIから確実に取得）
func fetchPRFiles(owner, repo, number, token string) ([]fileAdditions, error) {
	api := fmt.Sprintf("https://api.github.com/repos/%s/%s/pulls/%s/files?per_page=100", owner, repo, number)

	req, err := http.NewRequest("GET", api, nil)
	if err != nil {
		return nil, err
	}
	req.Header.Set("Accept", "application/vnd.github.v3+json")
	req.Header.Set("User-Agent", "pr-additions-go")
	req.Header.Set("Authorization", "Bearer "+token)

	client := &http.Client{Timeout: 30 * time.Second}
	res, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	defer res.Body.Close()
	if res.StatusCode < 200 || res.StatusCode >= 300 {
		body, _ := io.ReadAll(io.LimitReader(res.Body, 2048))
		return nil, fmt.Errorf("GitHub API %s: %s\n%s", api, res.Status, string(body))
	}

	var resp []ghPRFile
	if err := json.NewDecoder(res.Body).Decode(&resp); err != nil {
		return nil, err
	}

	var out []fileAdditions
	for _, f := range resp {
		if f.Patch == "" {
			// 巨大な差分やバイナリの場合 patch が欠落することがある
			continue
		}
		adds := parseUnifiedPatchAdditions(f.Patch)
		if len(adds) == 0 {
			continue
		}
		out = append(out, fileAdditions{Filename: f.Filename, Additions: adds})
	}
	return out, nil
}

// 単一ファイルの patch 文字列から追加行のみを抽出
func parseUnifiedPatchAdditions(patch string) []string {
	sc := bufio.NewScanner(strings.NewReader(patch))
	sc.Buffer(make([]byte, 0, 1024*1024), 1024*1024)
	inHunk := false
	var adds []string
	for sc.Scan() {
		line := sc.Text()
		if strings.HasPrefix(line, "@@") {
			inHunk = true
			continue
		}
		if strings.HasPrefix(line, "index ") ||
			strings.HasPrefix(line, "new file mode ") ||
			strings.HasPrefix(line, "deleted file mode ") ||
			strings.HasPrefix(line, "similarity index ") ||
			strings.HasPrefix(line, "rename from ") ||
			strings.HasPrefix(line, "rename to ") ||
			strings.HasPrefix(line, "diff --git ") ||
			strings.HasPrefix(line, "--- ") ||
			strings.HasPrefix(line, "+++") {
			continue
		}
		if inHunk && strings.HasPrefix(line, "+") && !strings.HasPrefix(line, "+++") {
			adds = append(adds, strings.TrimPrefix(line, "+"))
		}
	}
	return adds
}

// unified diff を読み、各ファイルの + 行だけを集める
func parseUnifiedDiff(diff string) []fileAdditions {
	sc := bufio.NewScanner(strings.NewReader(diff))
	sc.Buffer(make([]byte, 0, 1024*1024), 1024*1024) // 1MB 行まで
	var files []fileAdditions
	var cur *fileAdditions
	inHunk := false             // @@ 以後のハンク内か
	var fallbackFilename string // diff --git の b/ 側パス

	for sc.Scan() {
		line := sc.Text()

		if strings.HasPrefix(line, "diff --git ") {
			if cur != nil {
				files = append(files, *cur)
			}
			// diff --git a/.. b/.. から b/ 側パスを抽出
			fallbackFilename = ""
			fields := strings.Fields(line)
			if len(fields) >= 4 {
				bpart := fields[len(fields)-1]
				if strings.HasPrefix(bpart, "b/") {
					fallbackFilename = strings.TrimPrefix(bpart, "b/")
				}
			}
			if fallbackFilename == "" {
				if idx := strings.LastIndex(line, " b/"); idx >= 0 {
					fallbackFilename = strings.TrimPrefix(line[idx+1:], "b/")
				}
			}
			cur = &fileAdditions{Filename: fallbackFilename}
			inHunk = false
			continue
		}

		// どこで出ても "+++ b/..." はファイル境界として扱い、ファイル名を取得
		if strings.HasPrefix(line, "+++ b/") {
			// 直前のファイルを確定（追加行がある場合のみ）
			if cur != nil && len(cur.Additions) > 0 {
				files = append(files, *cur)
			}
			cur = &fileAdditions{Filename: strings.TrimPrefix(line, "+++ b/")}
			inHunk = false
			continue
		}

		if strings.HasPrefix(line, "@@") ||
			strings.HasPrefix(line, "index ") ||
			strings.HasPrefix(line, "new file mode ") ||
			strings.HasPrefix(line, "deleted file mode ") ||
			strings.HasPrefix(line, "similarity index ") ||
			strings.HasPrefix(line, "rename from ") ||
			strings.HasPrefix(line, "rename to ") ||
			strings.HasPrefix(line, "--- ") { // --- a/... は無視
			if strings.HasPrefix(line, "@@") {
				inHunk = true
			}
			continue
		}

		// 追加行: ハンク内で先頭が '+'
		if inHunk && strings.HasPrefix(line, "+") {
			if cur == nil {
				cur = &fileAdditions{}
			}
			cur.Additions = append(cur.Additions, strings.TrimPrefix(line, "+"))
		}
	}
	if cur != nil {
		files = append(files, *cur)
	}
	return files
}
