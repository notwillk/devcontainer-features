#!/usr/bin/env bash
set -euo pipefail

VERSION="${VERSION:-latest}"
PACKAGE="openhands"

export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y ca-certificates curl gnupg software-properties-common python3-pip python3-venv pipx

# Ensure Python 3.12 is available for the OpenHands virtualenv; install from deadsnakes PPA if needed.
if ! command -v python3.12 >/dev/null 2>&1; then
  add-apt-repository -y ppa:deadsnakes/ppa
  apt-get update -y
  apt-get install -y python3.12 python3.12-venv python3.12-distutils
fi

if ! command -v python3.12 >/dev/null 2>&1; then
  echo "python3.12 is required for OpenHands but could not be installed." >&2
  exit 1
fi

PYTHON_BIN="$(command -v python3.12)"

export PIPX_HOME="${PIPX_HOME:-/usr/local/pipx}"
export PIPX_BIN_DIR="${PIPX_BIN_DIR:-/usr/local/bin}"
export PIPX_DEFAULT_PYTHON="$PYTHON_BIN"
mkdir -p "$PIPX_HOME" "$PIPX_BIN_DIR"

SPEC="$PACKAGE"
if [ "$VERSION" != "latest" ] && [ "$VERSION" != "current" ]; then
  SPEC="${PACKAGE}==${VERSION#v}"
fi

pipx install --python "$PYTHON_BIN" "$SPEC"

# Confirm the CLI is available on PATH.
command -v openhands >/dev/null 2>&1
openhands --help >/dev/null

rm -rf /var/lib/apt/lists/*
