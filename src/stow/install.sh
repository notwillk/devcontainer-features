#!/usr/bin/env bash
set -e

echo "Installing GNU Stow..."

# Must be root inside the build
if [ "$(id -u)" -ne 0 ]; then
  echo "ERROR: install.sh must be run as root." >&2
  exit 1
fi

# Basic OS check (Debian/Ubuntu-ish)
if [ -f /etc/os-release ]; then
  . /etc/os-release
else
  echo "WARNING: /etc/os-release not found; proceeding anyway."
fi

if [ "${ID:-}" != "ubuntu" ] && [[ "${ID_LIKE:-}" != *debian* ]]; then
  echo "ERROR: This feature currently supports only Debian/Ubuntu-based images." >&2
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y --no-install-recommends stow
rm -rf /var/lib/apt/lists/*

echo "GNU Stow installed:"
if command -v stow >/dev/null 2>&1; then
  stow --version || true
else
  echo "WARN: stow not found on PATH after install." >&2
fi
