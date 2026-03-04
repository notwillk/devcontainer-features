#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP_PROJECT="$(mktemp -d)"
trap 'rm -rf "$TMP_PROJECT"' EXIT

cp -R "$PROJECT_ROOT/src" "$TMP_PROJECT/src"
mkdir -p "$TMP_PROJECT/test/copilot-auth-persist"

cat >"$TMP_PROJECT/test/copilot-auth-persist/test.sh" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=/dev/null
source dev-container-features-test-lib

CRED_DIR="/home/vscode/.vscode-server/data/User/globalStorage/github.copilot"

check "credential directory exists" test -d "$CRED_DIR"

check "credential directory is writable by vscode" bash -c "touch '${CRED_DIR}/.persist-test' && rm '${CRED_DIR}/.persist-test'"

check "credential directory owner is vscode" bash -c "stat -c '%U' '${CRED_DIR}' | grep -Fx vscode"

reportResults
EOS
chmod +x "$TMP_PROJECT/test/copilot-auth-persist/test.sh"

devcontainer features test \
  --project-folder "$TMP_PROJECT" \
  --features copilot-auth-persist \
  --base-image mcr.microsoft.com/devcontainers/base:ubuntu
