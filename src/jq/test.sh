#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP_PROJECT="$(mktemp -d)"
trap 'rm -rf "$TMP_PROJECT"' EXIT

cp -R "$PROJECT_ROOT/src" "$TMP_PROJECT/src"
mkdir -p "$TMP_PROJECT/test/jq"

cat >"$TMP_PROJECT/test/jq/test.sh" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=/dev/null
source dev-container-features-test-lib

check "jq available" jq --version

if [ -n "${VERSION:-}" ] && [ "${VERSION}" != "latest" ] && [ "${VERSION}" != "current" ]; then
  EXPECTED="${VERSION#jq-}"
  EXPECTED="${EXPECTED#v}"
  check "jq matches version" bash -lc "jq --version | sed 's/^jq-//' | grep -Fx \"${EXPECTED}\""
else
  check "jq version format" bash -lc "jq --version | grep -Eq '^jq-[0-9]+\\.[0-9]+\\.[0-9]+'"
fi

reportResults
EOS
chmod +x "$TMP_PROJECT/test/jq/test.sh"

devcontainer features test \
  --project-folder "$TMP_PROJECT" \
  --features jq \
  --base-image mcr.microsoft.com/devcontainers/base:ubuntu
