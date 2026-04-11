#!/usr/bin/env bash
set -euo pipefail

CONFIG_DIR="/mnt/opencode/config"
DATA_DIR="/mnt/opencode/data"

mkdir -p "$CONFIG_DIR" "$DATA_DIR"

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