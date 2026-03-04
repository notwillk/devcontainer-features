#!/usr/bin/env bash
set -euo pipefail

OPENCODE_VERSION="${VERSION:-latest}"
# Unset VERSION so the upstream installer does not read it as a version pin
# when we want the latest release.
unset VERSION

# Install OpenCode CLI. The installer always places the binary in
# $HOME/.opencode/bin, so we move it to /usr/local/bin afterwards.
if [ "${OPENCODE_VERSION}" = "latest" ]; then
  curl -fsSL https://opencode.ai/install | bash
else
  curl -fsSL https://opencode.ai/install | bash -s -- --version "${OPENCODE_VERSION}"
fi

# Relocate to /usr/local/bin so it is on PATH for all users
if [ -f "${HOME}/.opencode/bin/opencode" ]; then
  mv "${HOME}/.opencode/bin/opencode" /usr/local/bin/opencode
  rm -rf "${HOME}/.opencode"
fi

# Ensure credential directories exist with correct ownership so the volume
# mount is seeded with the right permissions on first use.
# Also ensure the full .local tree is owned by vscode — opencode creates
# ~/.local/state at startup and will fail if that directory is unwritable.
mkdir -p /home/vscode/.config/opencode
mkdir -p /home/vscode/.local/share/opencode
if id -u vscode &>/dev/null; then
  chown -R vscode:vscode /home/vscode/.config/opencode 2>/dev/null || true
  chown -R vscode:vscode /home/vscode/.local 2>/dev/null || true
fi
