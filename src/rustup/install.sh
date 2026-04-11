#!/usr/bin/env bash
set -euo pipefail

apt-get update -y
apt-get install -y curl build-essential
rm -rf /var/lib/apt/lists/*

export CARGO_HOME="/usr/local/cargo"
export RUSTUP_HOME="/usr/local/rustup"
export PATH="$CARGO_HOME/bin:$PATH"

mkdir -p "$CARGO_HOME" "$RUSTUP_HOME" "$RUSTUP_HOME/tmp"
chmod -R 777 "$CARGO_HOME" "$RUSTUP_HOME"

if ! command -v rustup &> /dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | CARGO_HOME="$CARGO_HOME" RUSTUP_HOME="$RUSTUP_HOME" sh -s -- -y
fi

if ! command -v rustup &> /dev/null; then
    echo "Error: rustup installation failed" >&2
    exit 1
fi

rustup --version

mkdir -p /etc/profile.d
cat > /etc/profile.d/rustup.sh << 'EOF'
export CARGO_HOME="/usr/local/cargo"
export RUSTUP_HOME="/usr/local/rustup"
export PATH="${CARGO_HOME}/bin:${PATH}"
EOF
chmod 644 /etc/profile.d/rustup.sh