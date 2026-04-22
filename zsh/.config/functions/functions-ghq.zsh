#!/bin/bash
# ghq + GitHub topic 付き検索
#   g          : ローカル ghq リポジトリを peco で選択して cd（最終更新日時順）
#                topic が登録されているリポジトリは末尾に [#tag1 #tag2] として表示され
#                peco の検索対象にもなる（例: "#go" で絞り込み）
#   g-refresh  : GitHub topic キャッシュを手動で更新する

GHQ_TOPICS_CACHE="${HOME}/.cache/ghq-topics.tsv"

function g-refresh() {
  if ! command -v gh >/dev/null 2>&1; then
    echo "gh command not found" >&2
    return 1
  fi
  mkdir -p "$(dirname "$GHQ_TOPICS_CACHE")"

  local tmp="${GHQ_TOPICS_CACHE}.tmp"
  local repos
  repos=$(ghq list | awk -F/ '$1=="github.com" && NF>=3 {printf "%s/%s\n", $2, $3}' | sort -u)
  local total
  total=$(printf "%s\n" "$repos" | grep -c .)
  if [[ "$total" -eq 0 ]]; then
    echo "No GitHub repositories under ghq" >&2
    return 1
  fi

  echo "Fetching topics for ${total} repositories..." >&2
  # gh api は 404 などの失敗時にエラー JSON を stdout に流すため、
  # 終了コードで成功時のみ結果を書き込む（失敗リポジトリは topic 空扱い）
  printf "%s\n" "$repos" \
    | xargs -P 10 -I {} sh -c '
        repo="$1"
        if topics=$(gh api "repos/$repo" --jq "(.topics // []) | join(\" \")" 2>/dev/null); then
          printf "%s\t%s\n" "$repo" "$topics"
        else
          printf "%s\t\n" "$repo"
        fi
      ' _ {} > "$tmp"

  mv "$tmp" "$GHQ_TOPICS_CACHE"
  local got
  got=$(wc -l < "$GHQ_TOPICS_CACHE" | tr -d ' ')
  echo "Updated: $GHQ_TOPICS_CACHE ($got repos)"
}

function g() {
  local ghq_root
  ghq_root=$(ghq root)
  local selected
  selected=$(
    ghq list \
      | xargs -I{} stat -f "%m %N" "${ghq_root}/{}" \
      | sort -nr \
      | cut -d" " -f2- \
      | awk -v root="${ghq_root}/" -v cache="$GHQ_TOPICS_CACHE" '
          BEGIN {
            while ((getline line < cache) > 0) {
              n = split(line, a, "\t")
              if (n >= 2) topics[a[1]] = a[2]
            }
            close(cache)
          }
          {
            rel = substr($0, length(root) + 1)
            key = rel
            sub(/^github\.com\//, "", key)
            if ((key in topics) && topics[key] != "") {
              nt = split(topics[key], t, " ")
              tagstr = ""
              for (i = 1; i <= nt; i++) {
                tagstr = tagstr "#" t[i] (i < nt ? " " : "")
              }
              printf "%s  [%s]\n", rel, tagstr
            } else {
              print rel
            }
          }
        ' \
      | peco
  )
  [[ -z "$selected" ]] && return
  local dir_rel="${selected%%  \[*}"
  builtin cd "${ghq_root}/${dir_rel}"
}
