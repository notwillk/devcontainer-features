#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP_PROJECT="$(mktemp -d)"
trap 'rm -rf "$TMP_PROJECT"' EXIT

cp -R "$PROJECT_ROOT/src" "$TMP_PROJECT/src"
mkdir -p "$TMP_PROJECT/test/1password-cli"

cat >"$TMP_PROJECT/test/1password-cli/test.sh" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=/dev/null
source dev-container-features-test-lib

DEFAULT_VERSION="2.32.1"
EXPECTED_VERSION="${VERSION:-$DEFAULT_VERSION}"
EXPECTED_VERSION="${EXPECTED_VERSION#v}"

check "op available" op --version
check "op binary group" bash -lc '[ "$(stat -c "%G" /usr/local/bin/op)" = "onepassword-cli" ]'
check "op binary setgid" bash -lc 'find /usr/local/bin/op -maxdepth 0 -perm -2000 | grep -Fx "/usr/local/bin/op"'
check "op matches version" bash -lc "op --version | grep -Fx \"${EXPECTED_VERSION}\""

reportResults
EOS
chmod +x "$TMP_PROJECT/test/1password-cli/test.sh"

devcontainer features test \
  --project-folder "$TMP_PROJECT" \
  --features 1password-cli \
  --base-image mcr.microsoft.com/devcontainers/base:ubuntu
