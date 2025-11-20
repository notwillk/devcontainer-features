#!/usr/bin/env bash
set -euo pipefail

V="${VERSION:-latest}"

apt-get update -y
apt-get install -y ca-certificates curl
rm -rf /var/lib/apt/lists/*

if [ "$V" = "latest" ] || [ "$V" = "current" ]; then
  TAG="$(curl -fsSL https://api.github.com/repos/jqlang/jq/releases/latest | sed -n 's/ *"tag_name": *"\([^"}]*\)".*/\1/p' | head -n1)"
else
  V="${V#jq-}"
  V="${V#v}"
  TAG="jq-${V}"
fi

ARCH="$(uname -m)"
case "$ARCH" in
  x86_64) CANDIDATES=("jq-linux64" "jq-linux-amd64" "jq-linux-x86_64") ;;
  aarch64|arm64) CANDIDATES=("jq-linux-aarch64" "jq-linux-arm64") ;;
  armv7l) CANDIDATES=("jq-linux-arm" "jq-linux-armhf") ;;
  *) echo "Unsupported architecture: $ARCH" >&2; exit 1 ;;
esac

mkdir -p /usr/local/bin
success=""
for asset in "${CANDIDATES[@]}"; do
  url="https://github.com/jqlang/jq/releases/download/${TAG}/${asset}"
  if curl -fsSL "$url" -o /usr/local/bin/jq; then
    success="yes"
    break
  fi
done

if [ -z "$success" ]; then
  echo "Failed to download jq for ${TAG} (${ARCH})" >&2
  exit 1
fi

chmod +x /usr/local/bin/jq

jq --version
