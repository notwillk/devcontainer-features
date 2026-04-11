#!/usr/bin/env bash
set -euo pipefail

V="${VERSION:-stable}"

apt-get update -y
apt-get install -y curl build-essential
rm -rf /var/lib/apt/lists/*

if ! command -v rustup &> /dev/null; then
    TOOLCHAIN="stable"
    if [ "$V" != "latest" ] && [ "$V" != "stable" ]; then
        TOOLCHAIN="${V#v}"
    fi
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain "$TOOLCHAIN"
    . "$HOME/.cargo/env"
fi

if [ "$V" != "latest" ] && [ "$V" != "stable" ]; then
    rustup install "${V#v}"
    rustup default "${V#v}"
fi

INSTALLED_VERSION=$(rustc --version | awk '{print $2}')
echo "Installed rustc version: $INSTALLED_VERSION"

if [ "$V" != "latest" ] && [ "$V" != "stable" ]; then
    EXPECTED="${V#v}"
    if [ "$INSTALLED_VERSION" != "$EXPECTED" ]; then
        echo "Error: Expected rustc version $EXPECTED but got $INSTALLED_VERSION" >&2
        exit 1
    fi
fi

cargo --version