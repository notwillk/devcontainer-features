#!/usr/bin/env bash
set -euo pipefail

V="${VERSION:-latest}"

# Resolve "latest" to a concrete version via GitHub API
if [ "$V" = "latest" ] || [ "$V" = "current" ]; then
  V="$(curl -fsSL https://api.github.com/repos/notwillk/sqlfs/releases/latest | grep '"tag_name"' | sed 's/.*"tag_name": *"v\?\([^"]*\)".*/\1/')"
else
  V="${V#v}"
fi

# Detect OS
case "$(uname -s)" in
  Linux)  OS="linux"  ;;
  Darwin) OS="darwin" ;;
  *) echo "Unsupported OS: $(uname -s)" >&2; exit 1 ;;
esac

# Detect ARCH
case "$(uname -m)" in
  x86_64)  ARCH="amd64" ;;
  aarch64|arm64) ARCH="arm64" ;;
  *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac

FILENAME="sqlfs_${V}_${OS}_${ARCH}.tar.gz"
URL="https://github.com/notwillk/sqlfs/releases/download/v${V}/${FILENAME}"

echo "Downloading sqlfs v${V} (${OS}/${ARCH})..."
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

curl -fsSL "$URL" -o "$TMP/$FILENAME"
tar -xzf "$TMP/$FILENAME" -C "$TMP"
install -m 0755 "$TMP/sqlfs" /usr/local/bin/sqlfs

sqlfs --version || true
