#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP_PROJECT="$(mktemp -d)"
trap 'rm -rf "$TMP_PROJECT"' EXIT

cp -R "$PROJECT_ROOT/src" "$TMP_PROJECT/src"
mkdir -p "$TMP_PROJECT/test/opencode"

cat >"$TMP_PROJECT/test/opencode/test.sh" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=/dev/null
source dev-container-features-test-lib

check "opencode available" opencode --version

check "config volume exists" test -d "/mnt/opencode/config"
check "data volume exists" test -d "/mnt/opencode/data"

check "config is writable" bash -c "touch '/mnt/opencode/config/.persist-test' && rm '/mnt/opencode/config/.persist-test'"
check "data is writable" bash -c "touch '/mnt/opencode/data/.persist-test' && rm '/mnt/opencode/data/.persist-test'"

reportResults
EOS
chmod +x "$TMP_PROJECT/test/opencode/test.sh"

devcontainer features test \
  --project-folder "$TMP_PROJECT" \
  --features opencode \
  --base-image mcr.microsoft.com/devcontainers/base:ubuntu