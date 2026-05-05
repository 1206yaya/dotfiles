#!/bin/bash

# @raycast.schemaVersion 1
# @raycast.title IT Blog Multi-Search
# @raycast.mode silent
# @raycast.packageName Search
# @raycast.icon 📝
# @raycast.argument1 { "type": "text", "placeholder": "search query" }
# @raycast.description Open the query across Japanese tech-blog sites (Medium / Qiita / Zenn / Note).

query="$1"
encoded=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$query")

urls=(
  "https://medium.com/search?q=${encoded}"
  "https://qiita.com/search?q=${encoded}&sort=stock"
  "https://zenn.dev/search?q=${encoded}"
  "https://note.com/search?q=${encoded}&context=note&mode=search"
)

for u in "${urls[@]}"; do
  open -g "$u"
done
