#!/usr/bin/env bash
set -euo pipefail

CONFIG_DIR="/mnt/opencode/config"
DATA_DIR="/mnt/opencode/data"

mkdir -p "$CONFIG_DIR" "$DATA_DIR"

NON_ROOT_USER="${CONTAINER_USER:-vscode}"
if id "$NON_ROOT_USER" &>/dev/null; then
    chown -R "$NON_ROOT_USER:$NON_ROOT_USER" "$CONFIG_DIR" "$DATA_DIR"
fi

OPENCODE_VERSION="${VERSION:-latest}"
unset VERSION

if [ "${OPENCODE_VERSION}" = "latest" ]; then
    curl -fsSL https://opencode.ai/install | bash
else
    curl -fsSL https://opencode.ai/install | bash -s -- --version "${OPENCODE_VERSION}"
fi

if [ -f "${HOME}/.opencode/bin/opencode" ]; then
    mv "${HOME}/.opencode/bin/opencode" /usr/local/bin/opencode
    rm -rf "${HOME}/.opencode"
fi