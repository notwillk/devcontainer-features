#!/usr/bin/env bash
set -euo pipefail

V="${VERSION:-latest}"

apt-get update -y
apt-get install -y ca-certificates python3 python3-venv
rm -rf /var/lib/apt/lists/*

if [ "$V" = "latest" ] || [ "$V" = "current" ]; then
  SPEC="bump2version"
else
  SPEC="bump2version==${V#v}"
fi

python3 -m venv /opt/bump2version
/opt/bump2version/bin/pip install --no-cache-dir --upgrade pip
/opt/bump2version/bin/pip install --no-cache-dir "$SPEC"

ln -sf /opt/bump2version/bin/bump2version /usr/local/bin/bump2version
ln -sf /opt/bump2version/bin/bumpversion /usr/local/bin/bumpversion

bump2version --help >/dev/null
