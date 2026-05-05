#!/bin/bash

# @raycast.schemaVersion 1
# @raycast.title IT Multi-Search
# @raycast.mode silent
# @raycast.packageName Search
# @raycast.icon 🔎
# @raycast.argument1 { "type": "text", "placeholder": "search query" }
# @raycast.description Open the query across major IT/tech sites in parallel (Alfred `it` workflow port).

query="$1"
encoded=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$query")

urls=(
  "https://medium.com/search?q=${encoded}"
  "https://www.youtube.com/results?search_query=${encoded}"
  "https://qiita.com/search?q=${encoded}&sort=stock"
  "https://twitter.com/search?q=${encoded}%20min_faves%3A100%20since%3A2020-01-01%20exclude%3Aretweets&src=typed_query"
  "https://www.google.com/search?q=${encoded}+site%3Ahttps%3A%2F%2Fzenn.dev"
  "https://www.amazon.co.jp/s?k=${encoded}"
  "https://xtech.nikkei.com/search/?KEYWORD=${encoded}"
  "https://booth.pm/ja/search/${encoded}"
  "https://www.udemy.com/courses/search/?src=ukw&q=${encoded}"
  "https://techbookfest.org/market/search?q=${encoded}"
  "https://note.com/search?q=${encoded}&context=note&mode=search"
)

for u in "${urls[@]}"; do
  open -g "$u"
done
