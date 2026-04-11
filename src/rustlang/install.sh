#!/usr/bin/env bash
set -euo pipefail

V="${VERSION:-stable}"

apt-get update -y
apt-get install -y curl build-essential
rm -rf /var/lib/apt/lists/*

export CARGO_HOME="/usr/local/cargo"
export RUSTUP_HOME="/usr/local/rustup"
export PATH="$CARGO_HOME/bin:$PATH"

if ! command -v rustup &> /dev/null; then
    TOOLCHAIN="stable"
    if [ "$V" != "latest" ] && [ "$V" != "stable" ]; then
        TOOLCHAIN="${V#v}"
    fi
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | CARGO_HOME="$CARGO_HOME" RUSTUP_HOME="$RUSTUP_HOME" sh -s -- -y --default-toolchain "$TOOLCHAIN"
fi

if ! command -v rustc &> /dev/null; then
    if [ "$V" != "latest" ] && [ "$V" != "stable" ]; then
        rustup default "${V#v}"
    else
        rustup default stable
    fi
fi

if [ "$V" != "latest" ] && [ "$V" != "stable" ]; then
    rustup install "${V#v}"
    rustup default "${V#v}"
fi

for binary in "$CARGO_HOME/bin"/*; do
    if [ -x "$binary" ]; then
        cp -f "$binary" "/usr/local/bin/$(basename "$binary")"
    fi
done

mkdir -p /etc/profile.d
cat > /etc/profile.d/rustup.sh << 'EOF'
export CARGO_HOME="/usr/local/cargo"
export RUSTUP_HOME="/usr/local/rustup"
export PATH="${CARGO_HOME}/bin:${PATH}"
EOF
chmod 644 /etc/profile.d/rustup.sh

INSTALLED_VERSION=$(rustc --version | awk '{print $2}')
echo "Installed rustc version: $INSTALLED_VERSION"

if [ "$V" != "latest" ] && [ "$V" != "stable" ]; then
    EXPECTED="${V#v}"
    if [ "$INSTALLED_VERSION" != "$EXPECTED" ]; then
        echo "Error: Expected rustc version $EXPECTED but got $INSTALLED_VERSION" >&2
        exit 1
    fi
fi

cargo --version
