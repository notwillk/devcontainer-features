#!/usr/bin/env bash
set -euo pipefail

V="${VERSION:-latest}"

apt-get update -y
apt-get install -y ca-certificates curl tar
rm -rf /var/lib/apt/lists/*

ARCH="$(uname -m)"
case "$ARCH" in
  x86_64) GH_ARCH="amd64" ;;
  aarch64|arm64) GH_ARCH="arm64" ;;
  *) echo "Unsupported architecture: $ARCH" >&2; exit 1 ;;
esac

RELEASE_API="https://api.github.com/repos/cli/cli/releases"
if [ "$V" = "latest" ]; then
  release_json="$(curl -fsSL "$RELEASE_API/latest")"
else
  V="${V#v}"
  release_json="$(curl -fsSL "$RELEASE_API/tags/v${V}")"
fi

TAG="$(printf '%s' "$release_json" | sed -n 's/^ *"tag_name": *"v\?\([^"]*\)".*/v\1/p' | head -n1)"
if [ -z "$TAG" ]; then
  TAG="v${V}"
fi
VERSION_NUMBER="${TAG#v}"

TARBALL="gh_${VERSION_NUMBER}_linux_${GH_ARCH}.tar.gz"
URL="https://github.com/cli/cli/releases/download/${TAG}/${TARBALL}"

tmp_tar="$(mktemp)"
curl -fsSL "$URL" -o "$tmp_tar"

tmp_dir="$(mktemp -d)"
tar -xzf "$tmp_tar" -C "$tmp_dir"
install -m 0755 "$tmp_dir/gh_${VERSION_NUMBER}_linux_${GH_ARCH}/bin/gh" /usr/local/bin/gh

rm -rf "$tmp_dir" "$tmp_tar"

gh --version
