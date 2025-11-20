#!/usr/bin/env bash
set -euo pipefail

V="${VERSION:-latest}"
PREFIX="/usr/local"

# Normalize version string: strip leading v when explicit
if [ "$V" != "latest" ] && [ "$V" != "current" ]; then
  V="${V#v}"
fi

# Ensure npm installs into a predictable prefix
npm install -g --prefix "$PREFIX" "pnpm@${V}"

# Make sure pnpm is on PATH
ln -sf "$PREFIX/lib/node_modules/pnpm/bin/pnpm.cjs" "$PREFIX/bin/pnpm"

pnpm --version
