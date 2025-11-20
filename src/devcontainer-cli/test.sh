#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP_PROJECT="$(mktemp -d)"
trap 'rm -rf "$TMP_PROJECT"' EXIT

# Prepare a temporary project layout the CLI expects (src + test), while only
# keeping this single committed test file alongside the feature code.
cp -R "$PROJECT_ROOT/src" "$TMP_PROJECT/src"
mkdir -p "$TMP_PROJECT/test/devcontainer-cli"

cat >"$TMP_PROJECT/test/devcontainer-cli/test.sh" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=/dev/null
source dev-container-features-test-lib

check "devcontainer reports its version" devcontainer --version

if [ -n "${VERSION:-}" ] && [ "${VERSION}" != "latest" ]; then
  check "devcontainer matches requested version" bash -lc "devcontainer --version | grep -Fx \"${VERSION}\""
else
  check "devcontainer version looks like semver" bash -lc "devcontainer --version | grep -Eq '^[0-9]+\\.[0-9]+\\.[0-9]+'"
fi

reportResults
EOS
chmod +x "$TMP_PROJECT/test/devcontainer-cli/test.sh"

cat >"$TMP_PROJECT/test/devcontainer-cli/scenarios.json" <<'EOS'
{
  "pinned_version": {
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
      "devcontainer-cli": {
        "version": "0.80.2"
      }
    }
  }
}
EOS

cat >"$TMP_PROJECT/test/devcontainer-cli/pinned_version.sh" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=/dev/null
source dev-container-features-test-lib

EXPECTED_VERSION="${VERSION:-0.80.2}"

check "devcontainer matches pinned version" bash -lc "devcontainer --version | grep -Fx \"${EXPECTED_VERSION}\""

reportResults
EOS
chmod +x "$TMP_PROJECT/test/devcontainer-cli/pinned_version.sh"

devcontainer features test \
  --project-folder "$TMP_PROJECT" \
  --features devcontainer-cli \
  --base-image mcr.microsoft.com/devcontainers/base:ubuntu
