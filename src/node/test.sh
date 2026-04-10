#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP_PROJECT="$(mktemp -d)"
trap 'rm -rf "$TMP_PROJECT"' EXIT

cp -R "$PROJECT_ROOT/src" "$TMP_PROJECT/src"
mkdir -p "$TMP_PROJECT/test/node"

cat >"$TMP_PROJECT/test/node/test.sh" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=/dev/null
source dev-container-features-test-lib

check "node present" node --version

if [ -n "${VERSION:-}" ] && [ "${VERSION}" != "latest" ] && [ "${VERSION}" != "current" ]; then
  EXPECTED="${VERSION#v}"
  check "node matches requested version" bash -lc "node --version | sed 's/^v//' | grep -Fx \"${EXPECTED}\""
else
  check "node version looks like semver" bash -lc "node --version | grep -Eq '^v?[0-9]+\\.[0-9]+\\.[0-9]+'"
fi

reportResults
EOS
chmod +x "$TMP_PROJECT/test/node/test.sh"

devcontainer features test \
  --project-folder "$TMP_PROJECT" \
  --features node \
  --base-image mcr.microsoft.com/devcontainers/base:ubuntu
