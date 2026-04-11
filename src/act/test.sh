#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP_PROJECT="$(mktemp -d)"
trap 'rm -rf "$TMP_PROJECT"' EXIT

cp -R "$PROJECT_ROOT/src" "$TMP_PROJECT/src"
mkdir -p "$TMP_PROJECT/test/act"

cat >"$TMP_PROJECT/test/act/test.sh" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=/dev/null
source dev-container-features-test-lib

check "act available" act --version

if [ -n "${VERSION:-}" ] && [ "${VERSION}" != "latest" ]; then
  EXPECTED="${VERSION#v}"
  check "act matches version" bash -lc "act --version | grep -Fx \"act version ${EXPECTED}\""
else
  check "act version format" bash -lc "act --version | grep -Eq '^act version [0-9]+\.[0-9]+\.[0-9]+'"
fi

reportResults
EOS
chmod +x "$TMP_PROJECT/test/act/test.sh"

devcontainer features test \
  --project-folder "$TMP_PROJECT" \
  --features act \
  --base-image mcr.microsoft.com/devcontainers/base:ubuntu