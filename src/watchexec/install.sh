#!/usr/bin/env bash
set -euo pipefail

V="${VERSION:-latest}"

apt-get update -y
apt-get install -y ca-certificates curl
rm -rf /var/lib/apt/lists/*

ARCH="$(uname -m)"
case "$ARCH" in
  x86_64) WX_ARCH="x86_64-unknown-linux-gnu" ;;
  aarch64|arm64) WX_ARCH="aarch64-unknown-linux-gnu" ;;
  *) echo "Unsupported architecture: $ARCH" >&2; exit 1 ;;
esac

if [ "$V" = "latest" ] || [ "$V" = "current" ]; then
  TAG="$(curl -fsSL https://api.github.com/repos/watchexec/watchexec/releases/latest | sed -n 's/ *"tag_name": *"v\?\([^"}]*\)".*/\1/p' | head -n1)"
else
  TAG="${V#v}"
fi

URL="https://github.com/watchexec/watchexec/releases/download/v${TAG}/watchexec-${TAG}-${WX_ARCH}.deb"

curl -fsSL "$URL" -o /tmp/watchexec.deb
dpkg -i /tmp/watchexec.deb
rm /tmp/watchexec.deb

watchexec --version
