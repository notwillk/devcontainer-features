#!/usr/bin/env bash
set -euo pipefail

CONFIG="/mnt/opencode/config"
DATA="/mnt/opencode/data"

# Ensure persistence volumes exist
mkdir -p "$CONFIG" "$DATA"

# Optional compatibility layer (only if downstream tools expect XDG paths)
if [ -n "${HOME:-}" ]; then
  mkdir -p "$HOME/.config" "$HOME/.local/share"

  ln -sfn "$CONFIG" "$HOME/.config/opencode"
  ln -sfn "$DATA" "$HOME/.local/share/opencode"
fi

echo "onCreate complete"
