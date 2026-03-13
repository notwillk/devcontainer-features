#!/usr/bin/env bash
set -euo pipefail

VERSION="${VERSION:-latest}"
PROVIDER="${PROVIDER:-}"
MODEL="${MODEL:-}"
API_KEY="${API_KEY:-}"
BASE_URL="${BASE_URL:-}"
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
# the runtime devcontainer user. Installing for the runtime user is required
# because devcontainer CLI runs tests as that user.
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

write_settings_for_user() {
  local target_user=$1
  local home_dir
  home_dir="$(getent passwd "$target_user" | cut -d: -f6)"
  [ -n "$home_dir" ] || return 0

  local settings_dir="${home_dir}/.openhands"
  local settings_file="${settings_dir}/agent_settings.json"
  local model_value="${MODEL}"
  local venv_python="${home_dir}/.local/pipx/venvs/${PACKAGE}/bin/python"

  if [ -n "$PROVIDER" ] && [ -n "$model_value" ] && [ "${model_value#*/}" = "$model_value" ]; then
    model_value="${PROVIDER}/${model_value}"
  fi

  mkdir -p "$settings_dir"
  [ -x "$venv_python" ] || return 0

  "$venv_python" - "$model_value" "$API_KEY" "$BASE_URL" "$settings_file" <<'PY'
from pathlib import Path
import sys

from openhands.sdk import LLM
from openhands_cli.utils import get_default_cli_agent

model = sys.argv[1].strip()
api_key = sys.argv[2].strip()
base_url = sys.argv[3].strip()
settings_file = Path(sys.argv[4])

llm_kwargs = {"usage_id": "agent"}
if model:
    llm_kwargs["model"] = model
if api_key:
    llm_kwargs["api_key"] = api_key
if base_url:
    llm_kwargs["base_url"] = base_url

agent = get_default_cli_agent(LLM(**llm_kwargs))
settings_file.write_text(
    agent.model_dump_json(context={"expose_secrets": True}, indent=2) + "\n",
    encoding="utf-8",
)
PY

  chown "$target_user":"$target_user" "$settings_dir" "$settings_file" 2>/dev/null || true
  chmod 700 "$settings_dir" 2>/dev/null || true
  chmod 600 "$settings_file" 2>/dev/null || true
}

# Always install for root (build-time), then for the resolved remote user when present.
TARGET_USERS=("root")
REMOTE_USER="${_REMOTE_USER:-}"
if [ -n "$REMOTE_USER" ] && [ "$REMOTE_USER" != "root" ] && id "$REMOTE_USER" >/dev/null 2>&1; then
  TARGET_USERS+=("$REMOTE_USER")
elif id vscode >/dev/null 2>&1; then
  TARGET_USERS+=("vscode")
fi

for target_user in "${TARGET_USERS[@]}"; do
  install_for_user "$target_user"
done

# If any LLM settings were provided via feature options, materialize them as
# ~/.openhands/agent_settings.json for installed users.
if [ -n "$PROVIDER$MODEL$API_KEY$BASE_URL" ]; then
  for target_user in "${TARGET_USERS[@]}"; do
    write_settings_for_user "$target_user"
  done
fi

# Confirm the CLI is available on PATH.
command -v openhands >/dev/null 2>&1
openhands --help >/dev/null

rm -rf /var/lib/apt/lists/*
