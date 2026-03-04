#!/usr/bin/env bash
set -euo pipefail

mkdir -p /home/vscode/.vscode-server/data/User/globalStorage/github.copilot
if id -u vscode &>/dev/null; then
  chown -R vscode:vscode /home/vscode/.vscode-server/data/User/globalStorage/github.copilot 2>/dev/null || true
fi
