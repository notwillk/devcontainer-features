#!/usr/bin/env bash
set -euo pipefail

V="${VERSION:-latest}"

apt-get update -y
apt-get install -y ca-certificates python3 python3-venv
rm -rf /var/lib/apt/lists/*

if [ "$V" = "latest" ] || [ "$V" = "current" ]; then
  SPEC="yamllint"
else
  SPEC="yamllint==${V#v}"
fi

python3 -m venv /opt/yamllint
/opt/yamllint/bin/pip install --no-cache-dir --upgrade pip
/opt/yamllint/bin/pip install --no-cache-dir "$SPEC"
ln -sf /opt/yamllint/bin/yamllint /usr/local/bin/yamllint

yamllint --version
