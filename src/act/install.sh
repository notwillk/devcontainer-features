#!/usr/bin/env bash
set -euo pipefail

V="${VERSION:-latest}"

apt-get update -y
apt-get install -y ca-certificates curl tar
rm -rf /var/lib/apt/lists/*

ARCH="$(uname -m)"
case "$ARCH" in
  x86_64) ACT_ARCH="x86_64" ;;
  aarch64|arm64) ACT_ARCH="arm64" ;;
  *) echo "Unsupported architecture: $ARCH" >&2; exit 1 ;;
esac

if [ "$V" = "latest" ]; then
  LATEST_URL="$(curl -fsSLI -o /dev/null -w '%{url_effective}' https://github.com/nektos/act/releases/latest)"
  TAG="${LATEST_URL##*/}"
else
  V="${V#v}"
  TAG="v${V}"
fi

if [ -z "$TAG" ] || [ "$TAG" = "latest" ]; then
  echo "Unable to resolve the latest act release tag" >&2
  exit 1
fi

TARBALL="act_Linux_${ACT_ARCH}.tar.gz"
URL="https://github.com/nektos/act/releases/download/${TAG}/${TARBALL}"

tmp_tar="$(mktemp)"
echo "Downloading act from ${URL}"
curl -fsSL "$URL" -o "$tmp_tar"

tmp_dir="$(mktemp -d)"
tar -xzf "$tmp_tar" -C "$tmp_dir"
install -m 0755 "$tmp_dir/act" /usr/local/bin/act

rm -rf "$tmp_dir" "$tmp_tar"

act --version
