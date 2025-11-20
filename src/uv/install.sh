#!/usr/bin/env bash
set -euo pipefail

V="${VERSION:-latest}"

apt-get update -y
apt-get install -y ca-certificates curl tar
rm -rf /var/lib/apt/lists/*

if [ "$V" = "latest" ] || [ "$V" = "current" ]; then
  V="$(curl -fsSL https://api.github.com/repos/astral-sh/uv/releases/latest | sed -n 's/ *"tag_name": *"\([^"}]*\)".*/\1/p' | head -n1)"
fi

ARCH="$(uname -m)"
case "$ARCH" in
  x86_64) UV_ARCH="x86_64-unknown-linux-gnu" ;;
  aarch64|arm64) UV_ARCH="aarch64-unknown-linux-gnu" ;;
  armv7l) UV_ARCH="armv7-unknown-linux-gnueabihf" ;;
  *) echo "Unsupported architecture: $ARCH" >&2; exit 1 ;;
esac

TARBALL="uv-${UV_ARCH}.tar.gz"
URL="https://github.com/astral-sh/uv/releases/download/${V}/${TARBALL}"

TMP_TAR="$(mktemp)"
curl -fsSL "$URL" -o "$TMP_TAR"

INSTALL_DIR="/usr/local/uv-${V}"
mkdir -p "$INSTALL_DIR"
tar -xzf "$TMP_TAR" -C "$INSTALL_DIR"
rm -f "$TMP_TAR"

install_bin="$(find "$INSTALL_DIR" -type f -name uv -perm -111 | head -n1)"
if [ -z "$install_bin" ]; then
  echo "uv binary not found after extraction" >&2
  exit 1
fi

ln -sf "$install_bin" /usr/local/bin/uv

uv --version
