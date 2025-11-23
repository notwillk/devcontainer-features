#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP_PROJECT="$(mktemp -d)"
trap 'rm -rf "$TMP_PROJECT"' EXIT

cp -R "$PROJECT_ROOT/src" "$TMP_PROJECT/src"
mkdir -p "$TMP_PROJECT/test/openscad-cli"

cat >"$TMP_PROJECT/test/openscad-cli/test.sh" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=/dev/null
source dev-container-features-test-lib

check "openscad available" openscad --version
# openscad writes version info to stderr, so capture both streams.
# OpenSCAD packages use year-based versions such as 2021.01.
check "openscad reports version" bash -lc "openscad --version 2>&1 | head -n1 | grep -Eq 'OpenSCAD version [0-9]{4}\\.[0-9]{2}'"

reportResults
EOS
chmod +x "$TMP_PROJECT/test/openscad-cli/test.sh"

devcontainer features test \
  --project-folder "$TMP_PROJECT" \
  --features openscad-cli \
  --base-image mcr.microsoft.com/devcontainers/base:ubuntu
