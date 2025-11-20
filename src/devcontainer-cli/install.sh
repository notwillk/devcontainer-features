#!/usr/bin/env bash
set -euo pipefail

V="${VERSION:-latest}"

# Ensure a Node.js runtime is available for the CLI install
if ! command -v npm >/dev/null 2>&1; then
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -y
  apt-get install -y ca-certificates curl gnupg
  curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
  apt-get install -y nodejs
  apt-get clean
  rm -rf /var/lib/apt/lists/*
fi

npm install -g @devcontainers/cli@"${V}"
