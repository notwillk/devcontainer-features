#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP_PROJECT="$(mktemp -d)"
trap 'rm -rf "$TMP_PROJECT"' EXIT

cp -R "$PROJECT_ROOT/src" "$TMP_PROJECT/src"
mkdir -p "$TMP_PROJECT/test/swift"

cat >"$TMP_PROJECT/test/swift/test.sh" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=/dev/null
source dev-container-features-test-lib

check "swift available" bash -lc "swift --version"
# swift --version outputs like: Swift version 6.0.3 (swift-6.0.3-RELEASE)
check "swift reports version" bash -lc "swift --version | grep -Eq 'Swift version [0-9]+\\.[0-9]+'"

reportResults
EOS
chmod +x "$TMP_PROJECT/test/swift/test.sh"

devcontainer features test \
  --project-folder "$TMP_PROJECT" \
  --features swift \
  --base-image mcr.microsoft.com/devcontainers/base:ubuntu
