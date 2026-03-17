#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP_PROJECT="$(mktemp -d)"
trap 'rm -rf "$TMP_PROJECT"' EXIT

cp -R "$PROJECT_ROOT/src" "$TMP_PROJECT/src"
mkdir -p "$TMP_PROJECT/test/prettier"

cat >"$TMP_PROJECT/test/prettier/test.sh" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=/dev/null
source dev-container-features-test-lib

check "prettier available" prettier --version

if [ -n "${VERSION:-}" ] && [ "${VERSION}" != "latest" ]; then
  EXPECTED="${VERSION#v}"
  check "prettier matches requested version" bash -lc "prettier --version | grep -F \"${EXPECTED}\""
fi

reportResults
EOS
chmod +x "$TMP_PROJECT/test/prettier/test.sh"

devcontainer features test \
  --project-folder "$TMP_PROJECT" \
  --features prettier \
  --base-image mcr.microsoft.com/devcontainers/base:ubuntu
