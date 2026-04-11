#!/usr/bin/env bash
set -euo pipefail

CONFIG="/mnt/opencode/config"
DATA="/mnt/opencode/data"

# Validate mounts exist
test -d "$CONFIG"
test -d "$DATA"

# Ensure proper ownership (volumes may reset permissions on restart)
NON_ROOT_USER="${_REMOTE_USER:-${CONTAINER_USER:-vscode}}"
if id "$NON_ROOT_USER" &>/dev/null; then
  chown -R "$NON_ROOT_USER:$NON_ROOT_USER" "$CONFIG" "$DATA"
fi

# Repair symlinks if compatibility layer is used
if [ -n "${HOME:-}" ]; then
  if [ -L "$HOME/.config/opencode" ]; then
    ln -sfn "$CONFIG" "$HOME/.config/opencode"
  fi

  if [ -L "$HOME/.local/share/opencode" ]; then
    ln -sfn "$DATA" "$HOME/.local/share/opencode"
  fi
fi

echo "postStart complete"
