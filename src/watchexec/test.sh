#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP_PROJECT="$(mktemp -d)"
trap 'rm -rf "$TMP_PROJECT"' EXIT

cp -R "$PROJECT_ROOT/src" "$TMP_PROJECT/src"
mkdir -p "$TMP_PROJECT/test/watchexec"

cat >"$TMP_PROJECT/test/watchexec/test.sh" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=/dev/null
source dev-container-features-test-lib

check "watchexec available" watchexec --version

if [ -n "${VERSION:-}" ] && [ "${VERSION}" != "latest" ] && [ "${VERSION}" != "current" ]; then
  EXPECTED="${VERSION#v}"
  check "watchexec matches version" bash -lc "watchexec --version | sed -n 's/.*[v ]\([0-9]\+\.[0-9]\+\.[0-9]\+\)$/\1/p' | grep -Fx \"${EXPECTED}\""
else
  check "watchexec version format" bash -lc "watchexec --version | grep -Eq '[0-9]+\.[0-9]+\.[0-9]+'"
fi

reportResults
EOS
chmod +x "$TMP_PROJECT/test/watchexec/test.sh"

devcontainer features test \
  --project-folder "$TMP_PROJECT" \
  --features watchexec \
  --base-image mcr.microsoft.com/devcontainers/base:ubuntu
