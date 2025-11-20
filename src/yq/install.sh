#!/usr/bin/env bash
set -euo pipefail

V="${VERSION:-latest}"

apt-get update -y
apt-get install -y ca-certificates curl
rm -rf /var/lib/apt/lists/*

ARCH="$(uname -m)"
case "$ARCH" in
  x86_64) YQ_ARCH="amd64" ;;
  aarch64|arm64) YQ_ARCH="arm64" ;;
  armv7l) YQ_ARCH="arm" ;;
  *) echo "Unsupported architecture: $ARCH" >&2; exit 1 ;;
esac

if [ "$V" = "latest" ] || [ "$V" = "current" ]; then
  TAG="$(curl -fsSL https://api.github.com/repos/mikefarah/yq/releases/latest | sed -n 's/ *"tag_name": *"v\?\([^"}]*\)".*/\1/p' | head -n1)"
else
  TAG="${V#v}"
fi

TAG="v${TAG}"
URL="https://github.com/mikefarah/yq/releases/download/${TAG}/yq_linux_${YQ_ARCH}"

curl -fsSL "$URL" -o /usr/local/bin/yq
chmod +x /usr/local/bin/yq

yq --version
