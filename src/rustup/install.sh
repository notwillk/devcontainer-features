#!/usr/bin/env bash
set -euo pipefail

apt-get update -y
apt-get install -y curl build-essential
rm -rf /var/lib/apt/lists/*

REMOTE_USER="${_REMOTE_USER:-root}"
REMOTE_USER_HOME="$(eval echo ~$REMOTE_USER)"

export CARGO_HOME="$REMOTE_USER_HOME/.cargo"
export RUSTUP_HOME="$REMOTE_USER_HOME/.rustup"
export PATH="$CARGO_HOME/bin:$PATH"

mkdir -p "$CARGO_HOME" "$RUSTUP_HOME" "$RUSTUP_HOME/tmp"

if [ "$REMOTE_USER" != "root" ] && id -u "$REMOTE_USER" &>/dev/null; then
    chown -R "$REMOTE_USER:$REMOTE_USER" "$CARGO_HOME" "$RUSTUP_HOME" 2>/dev/null || true
fi

if ! command -v rustup &> /dev/null; then
    su - "$REMOTE_USER" -c "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | CARGO_HOME=\"$CARGO_HOME\" RUSTUP_HOME=\"$RUSTUP_HOME\" sh -s -- -y"
fi

if ! command -v rustup &> /dev/null; then
    echo "Error: rustup installation failed" >&2
    exit 1
fi

# Fix ownership after installation so the remote user can use rustup
if [ "$REMOTE_USER" != "root" ] && id -u "$REMOTE_USER" &>/dev/null; then
    chown -R "$REMOTE_USER:$REMOTE_USER" "$CARGO_HOME" "$RUSTUP_HOME" 2>/dev/null || true
fi

rustup --version

mkdir -p /etc/profile.d
cat > /etc/profile.d/rustup.sh << 'PROFILEEOF'
export CARGO_HOME="$HOME/.cargo"
export RUSTUP_HOME="$HOME/.rustup"
export PATH="${CARGO_HOME}/bin:${PATH}"
PROFILEEOF
chmod 644 /etc/profile.d/rustup.sh