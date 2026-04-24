#!/usr/bin/env bash
set -euo pipefail

VERSION="${VERSION:-latest}"

# Install dependencies
apt-get update
apt-get install -y curl unzip ca-certificates

# Determine architecture
ARCH="$(uname -m)"
case "$ARCH" in
    x86_64) SWIFT_ARCH="x86_64" ;;
    aarch64|arm64) SWIFT_ARCH="aarch64" ;;
    *) echo "Unsupported architecture: $ARCH" >&2; exit 1 ;;
esac

# Get latest version if specified
if [ "$VERSION" = "latest" ]; then
    VERSION=$(curl -fsSL https://api.github.com/repos/apple/swift-protobuf/releases/latest | \
        sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p')
fi

# Add 'v' prefix if not present
if [[ ! "$VERSION" =~ ^v ]]; then
    VERSION="v${VERSION}"
fi

# Download protoc-gen-swift
PLUGIN_URL="https://github.com/apple/swift-protobuf/releases/download/${VERSION}/protoc-gen-swift-${VERSION}-linux-${SWIFT_ARCH}.zip"

echo "Downloading protoc-gen-swift ${VERSION} for ${SWIFT_ARCH}..."
curl -fsSL "$PLUGIN_URL" -o /tmp/protoc-gen-swift.zip

# Extract to /usr/local/bin
unzip -o /tmp/protoc-gen-swift.zip -d /usr/local/bin
rm -f /tmp/protoc-gen-swift.zip

chmod +x /usr/local/bin/protoc-gen-swift

# Verify installation
protoc-gen-swift --version
