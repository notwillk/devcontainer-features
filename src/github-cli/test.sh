#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP_PROJECT="$(mktemp -d)"
trap 'rm -rf "$TMP_PROJECT"' EXIT

cp -R "$PROJECT_ROOT/src" "$TMP_PROJECT/src"
mkdir -p "$TMP_PROJECT/test/github-cli"

cat >"$TMP_PROJECT/test/github-cli/test.sh" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=/dev/null
source dev-container-features-test-lib

check "gh available" gh --version

if [ -n "${VERSION:-}" ] && [ "${VERSION}" != "latest" ] && [ "${VERSION}" != "current" ]; then
  EXPECTED="${VERSION#v}"
  check "gh matches version" bash -lc "gh --version | cut -d' ' -f3 | sed 's/^v//' | grep -Fx \"${EXPECTED}\""
else
  check "gh version format" bash -lc "gh --version | cut -d' ' -f3 | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+'"
fi

reportResults
EOS
chmod +x "$TMP_PROJECT/test/github-cli/test.sh"

devcontainer features test \
  --project-folder "$TMP_PROJECT" \
  --features github-cli \
  --base-image mcr.microsoft.com/devcontainers/base:ubuntu
