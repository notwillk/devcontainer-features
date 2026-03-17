#!/usr/bin/env bash
set -euo pipefail

V="${VERSION:-latest}"
PREFIX="/usr/local"

npm install -g --prefix "$PREFIX" "prettier@${V}"

# Ensure we can execute the global binary in this build step.
export PATH="$PREFIX/bin:$PATH"

if [ ! -x "$PREFIX/bin/prettier" ]; then
  echo "prettier binary was not installed at $PREFIX/bin/prettier" >&2
  exit 1
fi

prettier --version
