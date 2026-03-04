#!/usr/bin/env bash
set -euo pipefail

mkdir -p /home/vscode/.config/openai
if id -u vscode &>/dev/null; then
  chown -R vscode:vscode /home/vscode/.config/openai 2>/dev/null || true
fi
