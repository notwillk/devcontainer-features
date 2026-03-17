#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP_PROJECT="$(mktemp -d)"
trap 'rm -rf "$TMP_PROJECT"' EXIT

cp -R "$PROJECT_ROOT/src" "$TMP_PROJECT/src"
mkdir -p "$TMP_PROJECT/test/check-jsonschema"

cat >"$TMP_PROJECT/test/check-jsonschema/test.sh" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=/dev/null
source dev-container-features-test-lib

check "check-jsonschema available" check-jsonschema --version

if [ -n "${VERSION:-}" ] && [ "${VERSION}" != "latest" ] && [ "${VERSION}" != "current" ]; then
  EXPECTED="${VERSION#v}"
  check "check-jsonschema matches version" bash -lc "check-jsonschema --version | grep -Eo '[0-9]+(\\.[0-9]+)+' | head -n1 | grep -Fx \"${EXPECTED}\""
else
  check "check-jsonschema version format" bash -lc "check-jsonschema --version | grep -Eo '[0-9]+(\\.[0-9]+)+' | head -n1 | grep -Eq '^[0-9]+\\.[0-9]+\\.[0-9]+'"
fi

reportResults
EOS
chmod +x "$TMP_PROJECT/test/check-jsonschema/test.sh"

devcontainer features test \
  --project-folder "$TMP_PROJECT" \
  --features check-jsonschema \
  --base-image mcr.microsoft.com/devcontainers/base:ubuntu
