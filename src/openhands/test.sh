#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP_PROJECT="$(mktemp -d)"
trap 'rm -rf "$TMP_PROJECT"' EXIT

cp -R "$PROJECT_ROOT/src" "$TMP_PROJECT/src"
mkdir -p "$TMP_PROJECT/test/openhands"

cat >"$TMP_PROJECT/test/openhands/test.sh" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=/dev/null
source dev-container-features-test-lib

check "python3.12 present" python3.12 --version
check "openhands available" openhands --help >/dev/null
check "pipx installed openhands" bash -lc "pipx list | grep -E 'package +openhands( |$)'"

if [ -n "${VERSION:-}" ] && [ "${VERSION}" != "latest" ] && [ "${VERSION}" != "current" ]; then
  # cli typically prints 'OpenHands vX.Y.Z' or similar
  check "openhands version matches" bash -lc "openhands --version 2>/dev/null | tr '[:upper:]' '[:lower:]' | grep -E '${VERSION#v}'"
fi

reportResults
EOS
chmod +x "$TMP_PROJECT/test/openhands/test.sh"

devcontainer features test \
  --project-folder "$TMP_PROJECT" \
  --features openhands \
  --base-image mcr.microsoft.com/devcontainers/base:ubuntu
