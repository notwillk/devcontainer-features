#!/usr/bin/env bash
set -euo pipefail

V="${VERSION:-latest}"

apt-get update -y
apt-get install -y ca-certificates curl tar
rm -rf /var/lib/apt/lists/*

ARCH="$(dpkg --print-architecture)"
case "$ARCH" in
  amd64) GOARCH="amd64" ;;
  arm64) GOARCH="arm64" ;;
  *) echo "Unsupported arch: $ARCH" >&2; exit 1 ;;
esac

if [ "$V" = "latest" ]; then
  V="$(curl -fsSL https://go.dev/VERSION?m=text | head -n1 | sed 's/^go//')"
else
  V="${V#go}"
  V="${V#v}"
fi

TMP_TAR="$(mktemp)"
curl -fsSL "https://go.dev/dl/go${V}.linux-${GOARCH}.tar.gz" -o "$TMP_TAR"

rm -rf /usr/local/go
tar -C /usr/local -xzf "$TMP_TAR"
rm -f "$TMP_TAR"

ln -sf /usr/local/go/bin/go /usr/local/bin/go
ln -sf /usr/local/go/bin/gofmt /usr/local/bin/gofmt

go version
