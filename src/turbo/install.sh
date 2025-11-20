#!/usr/bin/env bash
set -euo pipefail

V="${VERSION:-latest}"
PREFIX="/usr/local"

# Ensure npm uses a predictable global prefix
npm install -g --prefix "$PREFIX" turbo@"$V"

# Make sure the turbo binary is on PATH
ln -sf "$PREFIX/lib/node_modules/turbo/bin/turbo" "$PREFIX/bin/turbo"

turbo --version
