#!/usr/bin/env bash
set -euo pipefail

V="${VERSION:-latest}"

apt-get update -y
apt-get install -y ca-certificates python3 python3-venv
rm -rf /var/lib/apt/lists/*

if [ "$V" = "latest" ] || [ "$V" = "current" ]; then
  SPEC="check-jsonschema"
else
  SPEC="check-jsonschema==${V#v}"
fi

python3 -m venv /opt/check-jsonschema
/opt/check-jsonschema/bin/pip install --no-cache-dir --upgrade pip
/opt/check-jsonschema/bin/pip install --no-cache-dir "$SPEC"
ln -sf /opt/check-jsonschema/bin/check-jsonschema /usr/local/bin/check-jsonschema

check-jsonschema --version
