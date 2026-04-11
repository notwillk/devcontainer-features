#!/usr/bin/env bash
set -euo pipefail

# Note: Volume mounts happen at container runtime, not build time.
# Permission setup is handled by onCreateCommand in devcontainer-feature.json.

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