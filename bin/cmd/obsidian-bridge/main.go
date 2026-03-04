package main

import (
	"bytes"
	"fmt"
	"net/url"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
	"time"
)

// 設定定数
const (
	// ★重要: ここは必ずObsidian左上の表示名と一致させる
	VaultName  = "workspace"
	TargetNote = "10_notes/GolangInsight/Inbox.md"
)

func main() {
	if len(os.Args) < 4 {
		fmt.Println("Usage: bridge <ProjectName> <FilePath> <LineNumber> [SelectedText]")
		os.Exit(1)
	}

	projectName := os.Args[1]
	filePath := os.Args[2]
	lineNumber := os.Args[3]

	// 1. コード取得（引数 または クリップボード）
	var codeContent string
	var err error

	if len(os.Args) >= 5 && os.Args[4] != "" {
		codeContent = os.Args[4]
	} else {
		codeContent, err = getClipboardContent()
		if err != nil {
			fmt.Printf("❌ Error reading clipboard: %v\n", err)
			os.Exit(1)
		}
	}

	// 2. Markdown形式に整形
	formattedContent := formatObsidianNote(projectName, filePath, lineNumber, codeContent)

	// 3. 【変更点】整形済みデータをクリップボードにセットする
	if err := writeClipboard(formattedContent); err != nil {
		fmt.Printf("❌ Error writing to clipboard: %v\n", err)
		os.Exit(1)
	}
	fmt.Println("✅ Formatted content written to clipboard")

	// 4. 【変更点】Obsidianには「クリップボードを使って」とだけ伝える
	uri, err := sendToObsidian(VaultName, TargetNote)
	if err != nil {
		fmt.Printf("❌ Error sending to Obsidian: %v\n", err)
		os.Exit(1)
	}
	fmt.Printf("✅ Command sent to Obsidian\n")
	fmt.Printf("📝 URI: %s\n", uri)
}

// クリップボードに書き込む関数（OS別）
func writeClipboard(text string) error {
	var cmd *exec.Cmd

	switch runtime.GOOS {
	case "darwin":
		cmd = exec.Command("pbcopy")
	case "linux":
		cmd = exec.Command("xclip", "-selection", "clipboard", "-in")
	case "windows":
		cmd = exec.Command("powershell", "-command", "Set-Clipboard -Value $Input")
	default:
		return fmt.Errorf("unsupported platform: %s", runtime.GOOS)
	}

	cmd.Stdin = strings.NewReader(text)
	return cmd.Run()
}

func getClipboardContent() (string, error) {
	var cmd *exec.Cmd
	switch runtime.GOOS {
	case "darwin":
		cmd = exec.Command("pbpaste")
	case "linux":
		cmd = exec.Command("xclip", "-selection", "clipboard", "-o")
	case "windows":
		cmd = exec.Command("powershell", "Get-Clipboard")
	default:
		return "", fmt.Errorf("unsupported platform: %s", runtime.GOOS)
	}
	var out bytes.Buffer
	cmd.Stdout = &out
	if err := cmd.Run(); err != nil {
		return "", err
	}
	return out.String(), nil
}

func formatObsidianNote(project, fPath, lineNum, code string) string {
	fileName := filepath.Base(fPath)
	timestamp := time.Now().Format("2006-01-02 15:04:05")
	ideLink := fmt.Sprintf("goland://open?file=%s&line=%s", fPath, lineNum)

	return fmt.Sprintf("\n### Code Capture: %s (%s)\n"+
		"- **Project**:: [[%s]]\n"+
		"- **Source**:: [%s:%s](%s)\n"+
		"- **Path**:: `%s`\n\n"+
		"```go\n%s\n```\n"+
		"Insight:\n"+
		"Tags: #capture/code #%s\n",
		fileName, timestamp, project, fileName, lineNum, ideLink, fPath, code, project,
	)
}

func sendToObsidian(vault, notePath string) (string, error) {
	// dataパラメータは送らず、clipboard=true を送る
	vals := url.Values{}
	vals.Add("vault", vault)
	vals.Add("filepath", notePath)
	vals.Add("clipboard", "true") // ★これが重要
	vals.Add("mode", "append")

	uri := "obsidian://advanced-uri?" + vals.Encode()

	var cmd *exec.Cmd
	switch runtime.GOOS {
	case "darwin":
		cmd = exec.Command("open", uri)
	case "windows":
		cmd = exec.Command("cmd", "/c", "start", "", uri)
	case "linux":
		cmd = exec.Command("xdg-open", uri)
	default:
		return uri, fmt.Errorf("unsupported platform: %s", runtime.GOOS)
	}
	return uri, cmd.Start()
}
