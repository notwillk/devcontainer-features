#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP_PROJECT="$(mktemp -d)"
trap 'rm -rf "$TMP_PROJECT"' EXIT

cp -R "$PROJECT_ROOT/src" "$TMP_PROJECT/src"
mkdir -p "$TMP_PROJECT/test/protoc-gen-swift"

cat >"$TMP_PROJECT/test/protoc-gen-swift/test.sh" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=/dev/null
source dev-container-features-test-lib

check "protoc-gen-swift available" protoc-gen-swift --version
# protoc-gen-swift --version outputs like: protoc-gen-swift 1.28.2
check "protoc-gen-swift reports version" bash -lc "protoc-gen-swift --version | grep -Eq 'protoc-gen-swift [0-9]+\\.[0-9]+'"

reportResults
EOS
chmod +x "$TMP_PROJECT/test/protoc-gen-swift/test.sh"

devcontainer features test \
  --project-folder "$TMP_PROJECT" \
  --features protoc-gen-swift \
  --base-image mcr.microsoft.com/devcontainers/base:ubuntu
