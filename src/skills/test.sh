#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP_PROJECT="$(mktemp -d)"
trap 'rm -rf "$TMP_PROJECT"' EXIT

cp -R "$PROJECT_ROOT/src" "$TMP_PROJECT/src"
mkdir -p "$TMP_PROJECT/test/skills"

cat >"$TMP_PROJECT/test/skills/test.sh" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=/dev/null
source dev-container-features-test-lib

check "skills CLI available" skills --version

reportResults
EOS
chmod +x "$TMP_PROJECT/test/skills/test.sh"

devcontainer features test \
  --project-folder "$TMP_PROJECT" \
  --features skills \
  --base-image mcr.microsoft.com/devcontainers/base:ubuntu
