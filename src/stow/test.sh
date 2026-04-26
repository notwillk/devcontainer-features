#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP_PROJECT="$(mktemp -d)"
trap 'rm -rf "$TMP_PROJECT"' EXIT

cp -R "$PROJECT_ROOT/src" "$TMP_PROJECT/src"
mkdir -p "$TMP_PROJECT/test/stow"

cat >"$TMP_PROJECT/test/stow/test.sh" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=/dev/null
source dev-container-features-test-lib

check "stow available" stow --version
check "stow version format" bash -lc "stow --version | grep -Eq 'stow \(GNU Stow\) [0-9]+\.[0-9]+\.[0-9]+'"

reportResults
EOS
chmod +x "$TMP_PROJECT/test/stow/test.sh"

devcontainer features test \
  --project-folder "$TMP_PROJECT" \
  --features stow \
  --base-image mcr.microsoft.com/devcontainers/base:ubuntu
