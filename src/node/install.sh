#!/usr/bin/env bash
set -euo pipefail

V="${VERSION:-latest}"

apt-get update -y
apt-get install -y ca-certificates curl xz-utils
rm -rf /var/lib/apt/lists/*

if [ "$V" = "latest" ] || [ "$V" = "current" ]; then
  # Fetch latest full version (vX.Y.Z) from upstream index
  V="$(curl -fsSL https://nodejs.org/dist/index.tab | awk 'NR==2{v=$1;sub(/^v/, "", v); print v}')"
else
  V="${V#v}"  # strip leading v if provided
fi

ARCH="$(uname -m)"
case "$ARCH" in
  x86_64) NODE_ARCH="x64" ;;
  aarch64|arm64) NODE_ARCH="arm64" ;;
  armv7l) NODE_ARCH="armv7l" ;;
  *) echo "Unsupported architecture: $ARCH" >&2; exit 1 ;;
esac

TARBALL="node-v${V}-linux-${NODE_ARCH}.tar.xz"
URL="https://nodejs.org/dist/v${V}/${TARBALL}"

TMP_TARBALL="$(mktemp)"
curl -fsSL "$URL" -o "$TMP_TARBALL"

INSTALL_DIR="/usr/local/node-v${V}"
mkdir -p "$INSTALL_DIR"
tar -xJf "$TMP_TARBALL" -C "$INSTALL_DIR" --strip-components=1
rm -f "$TMP_TARBALL"

ln -sf "$INSTALL_DIR/bin/node" /usr/local/bin/node
ln -sf "$INSTALL_DIR/bin/npm" /usr/local/bin/npm
ln -sf "$INSTALL_DIR/bin/npx" /usr/local/bin/npx

node -v
npm -v
