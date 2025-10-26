package main

import (
	"fmt"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

// ~/Downloads　ディレクトリの 全ての　.m4a ファイルを .mp4　に変換する
// 変換後は　.m4a を削除する

// このコマンドを利用する
// ffmpeg -f lavfi -i color=c=black:s=1280x720 -i input.m4a -c:v libx264 -c:a aac -shortest output.mp4

func main() {
	// ホームディレクトリを取得
	homeDir, err := os.UserHomeDir()
	if err != nil {
		log.Fatalf("ホームディレクトリの取得に失敗しました: %v", err)
	}

	// Downloadsディレクトリのパス
	downloadsDir := filepath.Join(homeDir, "Downloads")

	// .m4aファイルを検索
	m4aFiles, err := findM4AFiles(downloadsDir)
	if err != nil {
		log.Fatalf("ファイル検索に失敗しました: %v", err)
	}

	if len(m4aFiles) == 0 {
		fmt.Println("変換する.m4aファイルが見つかりませんでした。")
		return
	}

	fmt.Printf("%d個の.m4aファイルが見つかりました。変換を開始します...\n", len(m4aFiles))

	// 各ファイルを変換
	for i, inputFile := range m4aFiles {
		fmt.Printf("[%d/%d] %s を変換中...\n", i+1, len(m4aFiles), filepath.Base(inputFile))

		outputFile := getOutputFilePath(inputFile)

		if err := convertM4AToMP4(inputFile, outputFile); err != nil {
			log.Printf("変換に失敗しました (%s): %v", inputFile, err)
			continue
		}

		// 変換が成功したら元のファイルを削除
		if err := os.Remove(inputFile); err != nil {
			log.Printf("元ファイルの削除に失敗しました (%s): %v", inputFile, err)
		} else {
			fmt.Printf("✓ %s -> %s (完了)\n", filepath.Base(inputFile), filepath.Base(outputFile))
		}
	}

	fmt.Println("すべての変換が完了しました。")
}

// findM4AFiles は指定されたディレクトリから.m4aファイルを検索する
func findM4AFiles(dir string) ([]string, error) {
	var m4aFiles []string

	err := filepath.Walk(dir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		// ディレクトリをスキップ
		if info.IsDir() {
			return nil
		}

		// .m4aファイルのみを対象とする
		if strings.ToLower(filepath.Ext(path)) == ".m4a" {
			m4aFiles = append(m4aFiles, path)
		}

		return nil
	})

	return m4aFiles, err
}

// getOutputFilePath は入力ファイルパスから出力ファイルパスを生成する
func getOutputFilePath(inputFile string) string {
	dir := filepath.Dir(inputFile)
	baseName := strings.TrimSuffix(filepath.Base(inputFile), filepath.Ext(inputFile))
	return filepath.Join(dir, baseName+".mp4")
}

// convertM4AToMP4 はffmpegを使用して.m4aファイルを.mp4に変換する
func convertM4AToMP4(inputFile, outputFile string) error {
	// ffmpegコマンドを構築
	cmd := exec.Command("ffmpeg",
		"-f", "lavfi",
		"-i", "color=c=black:s=1280x720",
		"-i", inputFile,
		"-c:v", "libx264",
		"-c:a", "aac",
		"-shortest",
		"-y", // 既存ファイルを上書き
		outputFile,
	)

	// コマンドを実行
	output, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("ffmpegの実行に失敗しました: %v, output: %s", err, string(output))
	}

	return nil
}
