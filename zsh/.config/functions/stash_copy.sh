#!/bin/bash

set -e

DATE=$(date +%Y%m%d)
BRANCH=$(git rev-parse --abbrev-ref HEAD)
DEST_DIR=~/Documents/stashList/${DATE}/${BRANCH}
cd ${HOME}/ghq/github.com/hrbrain/hrbrain/

if ! git stash list | grep -q .; then
  echo "❌ スタッシュが空です"
  exit 1
fi

echo "✅ スタッシュ内容を適用して、ファイルをコピーします"

# ワークツリーの変更がある場合だけ stash する
if [ -n "$(git status --porcelain)" ]; then
  echo "📦 ワークツリーを一時退避"
  git stash push -u -m "before-stash-export"
  STASH_TARGET="stash@{1}"
else
  echo "📦 ワークツリーはクリーン → 一時退避スキップ"
  STASH_TARGET="stash@{0}"
fi

# スタッシュ適用
git stash apply "$STASH_TARGET"

# status で変更ファイル取得（スペース区切り対策で IFS 使用）
echo "📄 変更ファイル一覧:"
IFS=$'\n' FILES=($(git status --porcelain | awk '{print $2}'))

mkdir -p "$DEST_DIR"

for FILE in "${FILES[@]}"; do
  if [ -f "$FILE" ]; then
    echo "📁 コピー: $FILE"
    mkdir -p "$(dirname "$DEST_DIR/$FILE")"
    cp "$FILE" "$DEST_DIR/$FILE"
  else
    echo "⚠️ ファイルが存在しないためスキップ: $FILE"
  fi
done

# patch 保存
git stash show -p "$STASH_TARGET" >"$DEST_DIR/stash.patch"

# 復元
echo "🔄 状態を復元"
git reset --hard
git clean -fd

if [ "$STASH_TARGET" = "stash@{1}" ]; then
  git stash pop stash@{0} >/dev/null
fi

echo "✅ 完了: $DEST_DIR"
