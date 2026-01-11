#!/bin/zsh

# Download cursor rules from awesome-cursor-rules-mdc repository
download-cursor-rules() {
  local target_dir="${1:-.}/.cursor/awesome-examples"
  
  echo "📥 Downloading cursor rules to: $target_dir"
  
  # Create directory
  mkdir -p "$target_dir"
  
  # Download files
  local files=(go python vim)
  local base_url="https://raw.githubusercontent.com/sanjeed5/awesome-cursor-rules-mdc/main/rules-mdc"
  
  for file in "${files[@]}"; do
    echo "  Downloading ${file}.mdc..."
    if curl -fsSL -o "$target_dir/${file}.mdc" "$base_url/${file}.mdc"; then
      echo "  ✓ ${file}.mdc"
    else
      echo "  ✗ Failed to download ${file}.mdc"
    fi
  done
  
  echo "✓ Complete!"
}
