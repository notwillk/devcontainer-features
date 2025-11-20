#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP_PROJECT="$(mktemp -d)"
trap 'rm -rf "$TMP_PROJECT"' EXIT

cp -R "$PROJECT_ROOT/src" "$TMP_PROJECT/src"
mkdir -p "$TMP_PROJECT/test/just"

cat >"$TMP_PROJECT/test/just/test.sh" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=/dev/null
source dev-container-features-test-lib

check "just available" just --version

if [ -n "${VERSION:-}" ] && [ "${VERSION}" != "latest" ]; then
  EXPECTED="${VERSION#v}"
  check "just matches version" bash -lc "just --version | awk '{print $2}' | sed 's/^v//' | grep -Fx \"${EXPECTED}\""
else
  check "just version format" bash -lc "just --version | awk '{print $2}' | grep -Eq '^[0-9]+\\.[0-9]+\\.[0-9]+'"
fi

reportResults
EOS
chmod +x "$TMP_PROJECT/test/just/test.sh"

devcontainer features test \
  --project-folder "$TMP_PROJECT" \
  --features just \
  --base-image mcr.microsoft.com/devcontainers/base:ubuntu
