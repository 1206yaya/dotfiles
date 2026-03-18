function obsidian() {
  local vault_path
  vault_path="$(cd "${1:-.}" 2>/dev/null && pwd)" || { echo "Invalid path: ${1:-.}" >&2; return 1; }
  local obsidian_json="$HOME/Library/Application Support/obsidian/obsidian.json"
  local obsidian_dir="$HOME/Library/Application Support/obsidian"
  if [[ ! -f "$obsidian_json" ]]; then
    echo "obsidian.json not found" >&2; return 1
  fi
  local needs_restart=false
  # Register vault if not already in obsidian.json
  local vault_id
  vault_id=$(jq -r --arg p "$vault_path" '.vaults | to_entries[] | select(.value.path == $p) | .key' "$obsidian_json")
  if [[ -z "$vault_id" ]]; then
    vault_id=$(openssl rand -hex 8)
    local ts=$(($(date +%s) * 1000))
    local tmp=$(mktemp)
    jq --arg id "$vault_id" --arg p "$vault_path" --argjson ts "$ts" \
      '.vaults[$id] = {path: $p, ts: $ts}' "$obsidian_json" > "$tmp" && mv "$tmp" "$obsidian_json"
    needs_restart=true
  fi
  # Create window config if missing
  if [[ ! -f "$obsidian_dir/$vault_id.json" ]]; then
    echo '{"isMaximized":true,"devTools":false,"zoom":0}' > "$obsidian_dir/$vault_id.json"
    needs_restart=true
  fi
  local vault_name
  vault_name="$(basename "$vault_path")"
  local encoded
  encoded=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$vault_name")
  if $needs_restart; then
    # Remember currently open vaults before restarting
    local open_vaults=()
    while IFS= read -r name; do
      [[ -n "$name" ]] && open_vaults+=("$name")
    done < <(jq -r '.vaults | to_entries[] | select(.value.open == true) | .value.path | split("/") | last' "$obsidian_json")
    echo "New vault registered. Restarting Obsidian..."
    osascript -e 'tell application "Obsidian" to quit' 2>/dev/null
    sleep 2
    # Reopen previously open vaults + new vault
    for v in "${open_vaults[@]}"; do
      local v_encoded
      v_encoded=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$v")
      open "obsidian://open?vault=$v_encoded"
      sleep 1
    done
    open "obsidian://open?vault=$encoded"
  else
    open "obsidian://open?vault=$encoded"
  fi
}
