#!/usr/bin/env bash
set -euo pipefail

CONFIG="/mnt/opencode/config"
DATA="/mnt/opencode/data"

# Ensure persistence volumes exist
mkdir -p "$CONFIG" "$DATA"

# Set proper ownership for the non-root user
# Determine the user: use _REMOTE_USER if set, otherwise fallback to vscode
NON_ROOT_USER="${_REMOTE_USER:-${CONTAINER_USER:-vscode}}"
if id "$NON_ROOT_USER" &>/dev/null; then
  chown -R "$NON_ROOT_USER:$NON_ROOT_USER" "$CONFIG" "$DATA"
fi

# Optional compatibility layer (only if downstream tools expect XDG paths)
if [ -n "${HOME:-}" ]; then
  mkdir -p "$HOME/.config" "$HOME/.local/share"

  ln -sfn "$CONFIG" "$HOME/.config/opencode"
  ln -sfn "$DATA" "$HOME/.local/share/opencode"
fi

echo "onCreate complete"
