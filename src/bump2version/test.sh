#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP_PROJECT="$(mktemp -d)"
trap 'rm -rf "$TMP_PROJECT"' EXIT

cp -R "$PROJECT_ROOT/src" "$TMP_PROJECT/src"
mkdir -p "$TMP_PROJECT/test/bump2version"

cat >"$TMP_PROJECT/test/bump2version/test.sh" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=/dev/null
source dev-container-features-test-lib

check "bump2version available" bump2version --help >/dev/null
check "bumpversion available" bumpversion --help >/dev/null

if [ -n "${VERSION:-}" ] && [ "${VERSION}" != "latest" ] && [ "${VERSION}" != "current" ]; then
  EXPECTED="${VERSION#v}"
  check "bump2version matches version" bash -lc "/opt/bump2version/bin/pip show bump2version | sed -n 's/^Version: //p' | grep -Fx \"${EXPECTED}\""
else
  check "bump2version version format" bash -lc "/opt/bump2version/bin/pip show bump2version | sed -n 's/^Version: //p' | grep -Eq '^[0-9]+\\.[0-9]+\\.[0-9]+'"
fi

reportResults
EOS
chmod +x "$TMP_PROJECT/test/bump2version/test.sh"

devcontainer features test \
  --project-folder "$TMP_PROJECT" \
  --features bump2version \
  --base-image mcr.microsoft.com/devcontainers/base:ubuntu
