#!/usr/bin/env bash
set -euo pipefail

VERSION="${VERSION:-6.0.3}"

# Install dependencies
apt-get update
apt-get install -y curl git gnupg2 lsb-release libicu-dev libcurl4-openssl-dev \
    libxml2-dev libz-dev libbsd-dev libsqlite3-dev libedit-dev libpython3-dev \
    pkg-config tzdata libz3-dev

# Determine architecture
ARCH="$(uname -m)"
case "$ARCH" in
    x86_64) SWIFTLY_ARCH="x86_64" ;;
    aarch64|arm64) SWIFTLY_ARCH="aarch64" ;;
    *) echo "Unsupported architecture: $ARCH" >&2; exit 1 ;;
esac

# Setup environment BEFORE installing swiftly
SWIFTLY_HOME_DIR="/usr/local/share/swiftly"
mkdir -p "$SWIFTLY_HOME_DIR"
export SWIFTLY_HOME_DIR
export SWIFTLY_BIN_DIR="/usr/local/bin"
export SWIFTLY_TOOLCHAINS_DIR="$SWIFTLY_HOME_DIR/toolchains"
mkdir -p "$SWIFTLY_TOOLCHAINS_DIR"
export PATH="${SWIFTLY_HOME_DIR}/bin:${SWIFTLY_BIN_DIR}:${PATH}"

# Install Swiftly (Swift toolchain manager)
echo "Installing Swiftly..."
curl -O "https://download.swift.org/swiftly/linux/swiftly-${SWIFTLY_ARCH}.tar.gz"
tar zxf "swiftly-${SWIFTLY_ARCH}.tar.gz"
./swiftly init --quiet-shell-followup --skip-install --no-modify-profile

# Move swiftly to system location if it installed to default location
if [ -d "$HOME/.local/share/swiftly" ]; then
    mv "$HOME/.local/share/swiftly"/* "$SWIFTLY_HOME_DIR/" 2>/dev/null || true
fi

# Install the requested Swift version
if [ "$VERSION" = "latest" ]; then
    echo "Installing latest Swift..."
    swiftly install latest --use --assume-yes
else
    # Remove 'v' prefix if present
    VERSION="${VERSION#v}"
    echo "Installing Swift ${VERSION}..."
    swiftly install "$VERSION" --use --assume-yes
fi

# Link swiftly's own binaries to system path
for bin in "$SWIFTLY_HOME_DIR"/bin/*; do
    if [ -f "$bin" ]; then
        name=$(basename "$bin")
        ln -sf "$bin" "/usr/local/bin/$name"
    fi
done

# Find and link the actual toolchain binaries
# First try the configured toolchain directory, then fall back to default location
find_toolchain() {
    local dir="$1"
    find "$dir" -maxdepth 1 -type d | grep -v "^$dir$" | head -1
}

toolchain_path=$(find_toolchain "$SWIFTLY_HOME_DIR/toolchains")
# Fallback to default location if env var wasn't respected during init
if [ -z "$toolchain_path" ] && [ -d "$HOME/.local/share/swiftly/toolchains" ]; then
    toolchain_path=$(find_toolchain "$HOME/.local/share/swiftly/toolchains")
    # Move toolchain to expected location for consistency
    if [ -n "$toolchain_path" ]; then
        mv "$HOME/.local/share/swiftly/toolchains"/* "$SWIFTLY_HOME_DIR/toolchains/" 2>/dev/null || true
        toolchain_path=$(find_toolchain "$SWIFTLY_HOME_DIR/toolchains")
    fi
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

# Create system-wide environment configuration so all users can find swiftly
# This is needed because swiftly stores absolute paths in its config
cat > /etc/profile.d/swiftly.sh << 'EOF'
export SWIFTLY_HOME_DIR="/usr/local/share/swiftly"
export SWIFTLY_BIN_DIR="/usr/local/bin"
export SWIFTLY_TOOLCHAINS_DIR="/usr/local/share/swiftly/toolchains"
export PATH="/usr/local/share/swiftly/bin:/usr/local/bin:${PATH}"
EOF
chmod 644 /etc/profile.d/swiftly.sh

# Also add to bash.bashrc for non-login shells
cat >> /etc/bash.bashrc << 'EOF'
export SWIFTLY_HOME_DIR="/usr/local/share/swiftly"
export SWIFTLY_BIN_DIR="/usr/local/bin"
export SWIFTLY_TOOLCHAINS_DIR="/usr/local/share/swiftly/toolchains"
export PATH="/usr/local/share/swiftly/bin:/usr/local/bin:${PATH}"
EOF

# Verify installation
hash -r
swift --version
