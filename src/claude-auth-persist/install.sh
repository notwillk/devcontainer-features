#!/usr/bin/env bash
set -euo pipefail

mkdir -p /home/vscode/.claude
if id -u vscode &>/dev/null; then
  chown -R vscode:vscode /home/vscode/.claude 2>/dev/null || true
fi
