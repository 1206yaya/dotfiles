#!/bin/bash


cms() {

USERNAME=$1

# アカウントのすべてのリポジトリを取得
repos=$(gh api users/$USERNAME/repos --jq '.[].name')
gh api users/rrousselGit/repos --jq '.[].name'
# 各リポジトリのコミットメッセージを取得
for repo in $repos; do
  echo "Commits for repository: $repo"
  gh api repos/$USERNAME/$repo/commits --jq '.[].commit.message'
done

}