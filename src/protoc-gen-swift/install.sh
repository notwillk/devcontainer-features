#!/usr/bin/env bash
set -euo pipefail

VERSION="${VERSION:-latest}"

# Install dependencies
apt-get update
apt-get install -y curl git ca-certificates

# Get version to install
if [ "$VERSION" = "latest" ]; then
    VERSION=$(curl -fsSL https://api.github.com/repos/apple/swift-protobuf/releases/latest | \
        sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p')
fi

# Remove 'v' prefix if present (git tags use it, but we might get it from VERSION)
VERSION="${VERSION#v}"

# Setup Swift environment (from swift feature)
export SWIFTLY_HOME_DIR="/usr/local/share/swiftly"
export SWIFTLY_BIN_DIR="/usr/local/bin"
export SWIFTLY_TOOLCHAINS_DIR="$SWIFTLY_HOME_DIR/toolchains"
export PATH="${SWIFTLY_HOME_DIR}/bin:${SWIFTLY_BIN_DIR}:${PATH}"

echo "Building protoc-gen-swift ${VERSION} from source..."

# Clone and build protoc-gen-swift
BUILD_DIR="$(mktemp -d)"
trap 'rm -rf "$BUILD_DIR"' EXIT

cd "$BUILD_DIR"
git clone --depth 1 --branch "$VERSION" https://github.com/apple/swift-protobuf.git
cd swift-protobuf

echo "Building protoc-gen-swift..."
swift build -c release --product protoc-gen-swift

# Install the binary
BINARY_PATH=".build/release/protoc-gen-swift"
if [ -f "$BINARY_PATH" ]; then
    cp "$BINARY_PATH" /usr/local/bin/protoc-gen-swift
    chmod +x /usr/local/bin/protoc-gen-swift
else
    echo "Error: protoc-gen-swift binary not found after build" >&2
    exit 1
fi

# Verify installation
hash -r
protoc-gen-swift --version
