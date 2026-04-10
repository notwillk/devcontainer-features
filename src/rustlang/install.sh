#!/usr/bin/env bash
set -euo pipefail

V="${VERSION:-latest}"

apt-get update -y
apt-get install -y rustc cargo
rm -rf /var/lib/apt/lists/*

if [ "$V" != "latest" ] && [ "$V" != "stable" ]; then
  apt-get install -y "rustc=$V" "cargo=$V" || true
fi

rustc --version
cargo --version