#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP_PROJECT="$(mktemp -d)"
trap 'rm -rf "$TMP_PROJECT"' EXIT

cp -R "$PROJECT_ROOT/src" "$TMP_PROJECT/src"
mkdir -p "$TMP_PROJECT/test/rustlang"

cat >"$TMP_PROJECT/test/rustlang/test.sh" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail

source dev-container-features-test-lib

check "rustc present" rustc --version
check "cargo present" cargo --version

reportResults
EOS
chmod +x "$TMP_PROJECT/test/rustlang/test.sh"

devcontainer features test \
  --project-folder "$TMP_PROJECT" \
  --features rustlang \
  --base-image mcr.microsoft.com/devcontainers/base:ubuntu