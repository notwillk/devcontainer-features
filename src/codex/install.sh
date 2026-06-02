#!/usr/bin/env bash
set -euo pipefail

npm install -g @openai/codex

NPM_PREFIX="$(npm config get prefix)"
CODEX_BIN="${NPM_PREFIX}/bin/codex"

if [ ! -x "$CODEX_BIN" ]; then
  echo "codex binary was not installed at $CODEX_BIN" >&2
  exit 1
fi

if [ "$CODEX_BIN" != "/usr/local/bin/codex" ]; then
  ln -sf "$CODEX_BIN" /usr/local/bin/codex
fi

codex --version
