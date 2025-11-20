#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP_PROJECT="$(mktemp -d)"
trap 'rm -rf "$TMP_PROJECT"' EXIT

# Mirror project layout the CLI expects
cp -R "$PROJECT_ROOT/src" "$TMP_PROJECT/src"
mkdir -p "$TMP_PROJECT/test/alias"

cat >"$TMP_PROJECT/test/alias/test.sh" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=/dev/null
source dev-container-features-test-lib

ALIAS_NAME="${NAME:-my-alias}"

check "alias command present" command -v "$ALIAS_NAME"
check "alias is executable" bash -lc "$ALIAS_NAME >/tmp/alias-out 2>/tmp/alias-err || true"

reportResults
EOS
chmod +x "$TMP_PROJECT/test/alias/test.sh"

devcontainer features test \
  --project-folder "$TMP_PROJECT" \
  --features alias \
  --base-image mcr.microsoft.com/devcontainers/base:ubuntu
