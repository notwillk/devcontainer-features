#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP_PROJECT="$(mktemp -d)"
trap 'rm -rf "$TMP_PROJECT"' EXIT

cp -R "$PROJECT_ROOT/src" "$TMP_PROJECT/src"
mkdir -p "$TMP_PROJECT/test/chromium"

cat >"$TMP_PROJECT/test/chromium/test.sh" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=/dev/null
source dev-container-features-test-lib

CHROMIUM_BIN="$(command -v chromium)"
HEADLESS_BIN="$(command -v chromium-headless)"

check "chromium launcher installed" test -x "$CHROMIUM_BIN"
check "chromium-headless launcher installed" test -x "$HEADLESS_BIN"
check "chromium launcher uses docker run" grep -Fq 'docker "${DOCKER_ARGS[@]}"' "$CHROMIUM_BIN"
check "chromium launcher default image" grep -Fq 'PUPPETEER_IMAGE:-ghcr.io/puppeteer/puppeteer:latest' "$CHROMIUM_BIN"
check "chromium launcher default platform" grep -Fq 'PUPPETEER_PLATFORM:-linux/amd64' "$CHROMIUM_BIN"
check "chromium launcher default sandbox mode" grep -Fq 'PUPPETEER_SANDBOX:-off' "$CHROMIUM_BIN"
check "chromium launcher has no-sandbox args" grep -Fq 'SANDBOX_ARGS=(--no-sandbox --disable-setuid-sandbox)' "$CHROMIUM_BIN"
check "chromium-headless has headless flag" grep -Fq -- '--headless=new' "$HEADLESS_BIN"
check "chromium-headless has dev-shm flag" grep -Fq -- '--disable-dev-shm-usage' "$HEADLESS_BIN"
check "chromium launcher has puppeteer cache fallback" grep -Fq '/.cache/puppeteer/chrome' "$CHROMIUM_BIN"

reportResults
EOS
chmod +x "$TMP_PROJECT/test/chromium/test.sh"

cat >"$TMP_PROJECT/test/chromium/scenarios.json" <<'EOS'
{
  "custom_defaults": {
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
      "chromium": {
        "image": "ghcr.io/puppeteer/puppeteer:24.9.0",
        "platform": "linux/arm64",
        "sandbox": "on"
      }
    }
  }
}
EOS

cat >"$TMP_PROJECT/test/chromium/custom_defaults.sh" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=/dev/null
source dev-container-features-test-lib

CHROMIUM_BIN="$(command -v chromium)"

check "custom image default rendered" grep -Fq 'PUPPETEER_IMAGE:-ghcr.io/puppeteer/puppeteer:24.9.0' "$CHROMIUM_BIN"
check "custom platform default rendered" grep -Fq 'PUPPETEER_PLATFORM:-linux/arm64' "$CHROMIUM_BIN"
check "custom sandbox default rendered" grep -Fq 'PUPPETEER_SANDBOX:-on' "$CHROMIUM_BIN"

reportResults
EOS
chmod +x "$TMP_PROJECT/test/chromium/custom_defaults.sh"

devcontainer features test \
  --project-folder "$TMP_PROJECT" \
  --features chromium \
  --base-image mcr.microsoft.com/devcontainers/base:ubuntu
