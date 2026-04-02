#!/usr/bin/env bash
set -euo pipefail

VERSION="${VERSION:-2.32.1}"

apt-get update -y
apt-get install -y ca-certificates wget unzip
rm -rf /var/lib/apt/lists/*

ARCH="$(uname -m)"
case "$ARCH" in
  x86_64) OP_ARCH="amd64" ;;
  i386|i686) OP_ARCH="386" ;;
  armv7l|armv6l) OP_ARCH="arm" ;;
  aarch64|arm64) OP_ARCH="arm64" ;;
  *) echo "Unsupported architecture: $ARCH" >&2; exit 1 ;;
esac

URL="https://cache.agilebits.com/dist/1P/op2/pkg/v${VERSION}/op_linux_${OP_ARCH}_v${VERSION}.zip"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

wget -q "$URL" -O "$TMP_DIR/op.zip"
unzip -q -d "$TMP_DIR/op" "$TMP_DIR/op.zip"
mv "$TMP_DIR/op/op" /usr/local/bin/op

groupadd -f onepassword-cli
chgrp onepassword-cli /usr/local/bin/op
chmod g+s /usr/local/bin/op

op --version
