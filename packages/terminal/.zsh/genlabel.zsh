genlabel() {
  pathDir="${HOME}/ghq/github.com/1206yaya/dotfiles/packages/terminal/.zsh/.github/labels.json"
  ls -la $pathDir
  # GitHub Labelsをセットアップ
  github-label-setup --token $GITHUB_TOKEN --labels $pathDir 1206ayay/$@
}

