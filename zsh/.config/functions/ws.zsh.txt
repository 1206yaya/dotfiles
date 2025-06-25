function ws() {
  if [ -z "$1" ]; then
    echo "Usage: ws <worktree-name>"
    return 1
  fi

  local WORKTREE_NAME="$1"
  local BASE_PATH="${HOME}/ghq/github.com/hrbrain"
  local WORKTREE_PATH="${BASE_PATH}/hrbrain.worktrees/${WORKTREE_NAME}"
  local WORKSPACE_DIR="${BASE_PATH}/code-workspaces"
  local WORKSPACE_FILE="${WORKSPACE_DIR}/${WORKTREE_NAME}.code-workspace"

  if [ ! -d "${WORKTREE_PATH}" ]; then
    echo "❌ Worktree path does not exist: ${WORKTREE_PATH}"
    return 1
  fi

  mkdir -p "${WORKSPACE_DIR}"

  cat >"${WORKSPACE_FILE}" <<EOF
{
  "folders": [
    {
      "path": "${WORKTREE_PATH}/apps/persia/app"
    },
    {
      "path": "${WORKTREE_PATH}/apps/persia/front"
    },
    {
      "path": "${WORKTREE_PATH}/apps/persia/schema"
    }
  ]
}
EOF

  echo "Workspace created: ${WORKSPACE_FILE}"
  code "${WORKSPACE_FILE}"
}
