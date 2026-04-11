#!/usr/bin/env bash
set -euo pipefail

CONFIG="/mnt/opencode/config"
DATA="/mnt/opencode/data"

# Validate mounts exist
test -d "$CONFIG"
test -d "$DATA"

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
