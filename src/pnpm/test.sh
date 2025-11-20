#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP_PROJECT="$(mktemp -d)"
trap 'rm -rf "$TMP_PROJECT"' EXIT

cp -R "$PROJECT_ROOT/src" "$TMP_PROJECT/src"
mkdir -p "$TMP_PROJECT/test/pnpm"

cat >"$TMP_PROJECT/test/pnpm/test.sh" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=/dev/null
source dev-container-features-test-lib

check "pnpm available" pnpm --version

if [ -n "${VERSION:-}" ] && [ "${VERSION}" != "latest" ] && [ "${VERSION}" != "current" ]; then
  EXPECTED="${VERSION#v}"
  check "pnpm matches version" bash -lc "pnpm --version | sed 's/^v//' | grep -Fx \"${EXPECTED}\""
else
  check "pnpm version format" bash -lc "pnpm --version | grep -Eq '^[0-9]+\\.[0-9]+\\.[0-9]+'"
fi

reportResults
EOS
chmod +x "$TMP_PROJECT/test/pnpm/test.sh"

devcontainer features test \
  --project-folder "$TMP_PROJECT" \
  --features pnpm \
  --base-image mcr.microsoft.com/devcontainers/base:ubuntu
