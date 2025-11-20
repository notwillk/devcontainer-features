#!/usr/bin/env bash
set -euo pipefail

V="${VERSION:-latest}"

apt-get update -y
apt-get install -y ca-certificates curl tar
rm -rf /var/lib/apt/lists/*

ARCH="$(uname -m)"
case "$ARCH" in
  x86_64) JUST_ARCH="x86_64-unknown-linux-musl" ;;
  aarch64|arm64) JUST_ARCH="aarch64-unknown-linux-musl" ;;
  *) echo "Unsupported architecture: $ARCH" >&2; exit 1 ;;
esac

RELEASE_API="https://api.github.com/repos/casey/just/releases"
if [ "$V" = "latest" ]; then
  release_json="$(curl -fsSL "$RELEASE_API/latest")"
else
  V="${V#v}"
  release_json="$(curl -fsSL "$RELEASE_API/tags/${V}")"
fi

# Grab tag from response or fall back to requested version
TAG="$(printf '%s' "$release_json" | sed -n 's/^ *"tag_name": *"v\?\([^"]*\)".*/\1/p' | head -n1)"
[ -n "$TAG" ] || TAG="${V#v}"

asset_url="$(printf '%s' "$release_json" | grep -o "https://[^\"]*just-[^\"]*${JUST_ARCH}[^\"]*\\.tar\\.gz" | head -n1)"
if [ -z "$asset_url" ]; then
  asset_url="https://github.com/casey/just/releases/download/v${TAG}/just-${TAG}-${JUST_ARCH}.tar.gz"
fi

tmp_tar="$(mktemp)"
curl -fsSL "$asset_url" -o "$tmp_tar"

mkdir -p /usr/local/bin
tar -xzf "$tmp_tar" -C /usr/local/bin just
rm -f "$tmp_tar"

chmod +x /usr/local/bin/just

just --version
