#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP_PROJECT="$(mktemp -d)"
trap 'rm -rf "$TMP_PROJECT"' EXIT

cp -R "$PROJECT_ROOT/src" "$TMP_PROJECT/src"
mkdir -p "$TMP_PROJECT/test/turbo"

cat >"$TMP_PROJECT/test/turbo/test.sh" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=/dev/null
source dev-container-features-test-lib

check "turbo available" turbo --version

if [ -n "${VERSION:-}" ] && [ "${VERSION}" != "latest" ]; then
  EXPECTED="${VERSION#v}"
  check "turbo matches requested version" bash -lc "turbo --version | grep -F \"${EXPECTED}\""
fi

reportResults
EOS
chmod +x "$TMP_PROJECT/test/turbo/test.sh"

devcontainer features test \
  --project-folder "$TMP_PROJECT" \
  --features turbo \
  --base-image mcr.microsoft.com/devcontainers/base:ubuntu
