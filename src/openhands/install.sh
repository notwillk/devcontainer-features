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

SPEC="$PACKAGE"
if [ "$VERSION" != "latest" ] && [ "$VERSION" != "current" ]; then
  SPEC="${PACKAGE}==${VERSION#v}"
fi

# Install with pipx for the current user (root when building) and, if present,
# the default devcontainer user (usually vscode). Installing for the runtime
# user is required because devcontainer CLI runs tests as that user, so a root-
# only install would not be visible to `pipx list`.
install_for_user() {
  local target_user=$1
  local home_dir
  home_dir="$(getent passwd "$target_user" | cut -d: -f6)"
  [ -n "$home_dir" ] || return 0

  # Use a user-writable bin dir for non-root installs to avoid permission errors
  # when pipx tries to manage /usr/local/bin. Root keeps the global bin location
  # so the CLI is on PATH for all users.
  local bin_dir="/usr/local/bin"
  if [ "$target_user" != "root" ]; then
    bin_dir="${home_dir}/.local/bin"
  fi

  local env_vars="PIPX_HOME=${home_dir}/.local/pipx PIPX_BIN_DIR=${bin_dir} PIPX_DEFAULT_PYTHON=${PYTHON_BIN}"
  # Use --force so reruns replace existing installs cleanly.
  if [ "$target_user" = "root" ]; then
    env $env_vars pipx install --python "$PYTHON_BIN" --force "$SPEC"
  else
    if command -v sudo >/dev/null 2>&1; then
      sudo -u "$target_user" env $env_vars pipx install --python "$PYTHON_BIN" --force "$SPEC"
    else
      su - "$target_user" -c "env $env_vars pipx install --python '$PYTHON_BIN' --force '$SPEC'"
    fi
  fi
}

# Always install for root (build-time), then try the common devcontainer user.
install_for_user root

# The devcontainers base images default to user 'vscode'; install there when it exists.
if id vscode >/dev/null 2>&1; then
  install_for_user vscode
fi

# Confirm the CLI is available on PATH.
command -v openhands >/dev/null 2>&1
openhands --help >/dev/null

rm -rf /var/lib/apt/lists/*
