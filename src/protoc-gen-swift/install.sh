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

# Install Swift if not present
if ! command -v swift &>/dev/null; then
    echo "Installing Swift toolchain..."
    
    # Determine architecture
    ARCH="$(uname -m)"
    case "$ARCH" in
        x86_64) SWIFTLY_ARCH="x86_64" ;;
        aarch64|arm64) SWIFTLY_ARCH="aarch64" ;;
        *) echo "Unsupported architecture: $ARCH" >&2; exit 1 ;;
    esac
    
    # Install Swift dependencies
    apt-get install -y gnupg2 lsb-release libicu-dev libcurl4-openssl-dev \
        libxml2-dev libz-dev libbsd-dev libsqlite3-dev libedit-dev libpython3-dev \
        pkg-config tzdata libz3-dev
    
    # Setup environment
    SWIFTLY_HOME_DIR="/usr/local/share/swiftly"
    mkdir -p "$SWIFTLY_HOME_DIR"
    export SWIFTLY_HOME_DIR
    export SWIFTLY_BIN_DIR="/usr/local/bin"
    export SWIFTLY_TOOLCHAINS_DIR="$SWIFTLY_HOME_DIR/toolchains"
    mkdir -p "$SWIFTLY_TOOLCHAINS_DIR"
    export PATH="${SWIFTLY_HOME_DIR}/bin:${SWIFTLY_BIN_DIR}:${PATH}"
    
    # Install Swiftly and latest Swift
    curl -fsSL "https://download.swift.org/swiftly/linux/swiftly-${SWIFTLY_ARCH}.tar.gz" -o /tmp/swiftly.tar.gz
    tar zxf /tmp/swiftly.tar.gz -C /tmp
    
    # Run init which installs swiftly to SWIFTLY_BIN_DIR (/usr/local/bin)
    /tmp/swiftly init --quiet-shell-followup --skip-install --no-modify-profile
    
    # Move swiftly data to system location
    if [ -d "$HOME/.local/share/swiftly" ]; then
        mv "$HOME/.local/share/swiftly"/* "$SWIFTLY_HOME_DIR/" 2>/dev/null || true
    fi
    
    # Install latest Swift using the installed swiftly binary
    swiftly install latest --use --assume-yes
    
    # Link swiftly binaries
    for bin in "$SWIFTLY_HOME_DIR"/bin/*; do
        if [ -f "$bin" ]; then
            name=$(basename "$bin")
            ln -sf "$bin" "/usr/local/bin/$name"
        fi
    done
    
    # Find and link toolchain binaries
    toolchain_path=$(find "$SWIFTLY_HOME_DIR/toolchains" -maxdepth 1 -type d | grep -v "^$SWIFTLY_HOME_DIR/toolchains$" | head -1)
    if [ -z "$toolchain_path" ] && [ -d "$HOME/.local/share/swiftly/toolchains" ]; then
        mv "$HOME/.local/share/swiftly/toolchains"/* "$SWIFTLY_HOME_DIR/toolchains/" 2>/dev/null || true
        toolchain_path=$(find "$SWIFTLY_HOME_DIR/toolchains" -maxdepth 1 -type d | grep -v "^$SWIFTLY_HOME_DIR/toolchains$" | head -1)
    fi
    
    if [ -n "$toolchain_path" ] && [ -d "$toolchain_path/usr/bin" ]; then
        for bin in "$toolchain_path"/usr/bin/swift*; do
            if [ -f "$bin" ]; then
                name=$(basename "$bin")
                if [ ! -e "/usr/local/bin/$name" ]; then
                    ln -sf "$bin" "/usr/local/bin/$name"
                fi
            fi
        done
    fi
    
    rm -f /tmp/swiftly.tar.gz /tmp/swiftly
    hash -r
fi

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
