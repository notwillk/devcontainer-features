#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP_PROJECT="$(mktemp -d)"
trap 'rm -rf "$TMP_PROJECT"' EXIT

cp -R "$PROJECT_ROOT/src" "$TMP_PROJECT/src"
mkdir -p "$TMP_PROJECT/test/protoc"

cat >"$TMP_PROJECT/test/protoc/test.sh" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=/dev/null
source dev-container-features-test-lib

check "protoc available" protoc --version
# protoc --version outputs like: libprotoc 25.3
check "protoc reports version" bash -lc "protoc --version | grep -Eq 'libprotoc [0-9]+\\.[0-9]+'"

reportResults
EOS
chmod +x "$TMP_PROJECT/test/protoc/test.sh"

devcontainer features test \
  --project-folder "$TMP_PROJECT" \
  --features protoc \
  --base-image mcr.microsoft.com/devcontainers/base:ubuntu
