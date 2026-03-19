#!/bin/sh

# macOS のシステムスリープ時間を変更する
# Usage: power 6h | power 20m | power 0

if [ -z "$1" ]; then
    echo "Usage: power <duration>"
    echo "  例: power 6h   (6時間)"
    echo "       power 20m  (20分)"
    echo "       power 0    (スリープ無効)"
    echo ""
    echo "現在の設定:"
    pmset -g | grep -E "^\s*(sleep|disksleep|displaysleep)"
    exit 0
fi

arg="$1"

case "$arg" in
    0)
        minutes=0
        ;;
    *h)
        hours="${arg%h}"
        minutes=$((hours * 60))
        ;;
    *m)
        minutes="${arg%m}"
        ;;
    *)
        echo "Error: 形式が不正です。例: 6h, 20m, 0"
        exit 1
        ;;
esac

echo "📌 システムスリープを ${arg} (${minutes}分) に設定"

sudo pmset -a disksleep "$minutes"
sudo pmset -a sleep "$minutes"

echo "[ OK ] 設定完了"
echo ""
echo "現在の設定:"
pmset -g custom | grep -E "^\s*(sleep|disksleep|displaysleep)"
