#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP_PROJECT="$(mktemp -d)"
trap 'rm -rf "$TMP_PROJECT"' EXIT

cp -R "$PROJECT_ROOT/src" "$TMP_PROJECT/src"
mkdir -p "$TMP_PROJECT/test/openhands"

cat >"$TMP_PROJECT/test/openhands/test.sh" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=/dev/null
source dev-container-features-test-lib

check "python3.12 present" python3.12 --version
check "openhands available" openhands --help >/dev/null
check "pipx installed openhands" bash -lc "pipx list | grep -E 'package +openhands( |$)'"

if [ -n "${VERSION:-}" ] && [ "${VERSION}" != "latest" ] && [ "${VERSION}" != "current" ]; then
  # cli typically prints 'OpenHands vX.Y.Z' or similar
  check "openhands version matches" bash -lc "openhands --version 2>/dev/null | tr '[:upper:]' '[:lower:]' | grep -E '${VERSION#v}'"
fi

reportResults
EOS
chmod +x "$TMP_PROJECT/test/openhands/test.sh"

cat >"$TMP_PROJECT/test/openhands/scenarios.json" <<'EOS'
{
  "custom_settings": {
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
      "openhands": {
        "provider": "litellm",
        "model": "fireworks/kimi-k2p5",
        "api_key": "${FIREWORKS_API_KEY}",
        "base_url": "https://api.fireworks.ai/inference/v1"
      }
    }
  }
}
EOS

cat >"$TMP_PROJECT/test/openhands/custom_settings.sh" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=/dev/null
source dev-container-features-test-lib

SETTINGS_FILE="$HOME/.openhands/agent_settings.json"

check "settings file exists" test -f "$SETTINGS_FILE"
check "settings is valid json" python3 -m json.tool "$SETTINGS_FILE" >/dev/null
check "agent settings kind" grep -Eq '"kind"[[:space:]]*:[[:space:]]*"Agent"' "$SETTINGS_FILE"
check "agent llm model set" grep -Eq '"model"[[:space:]]*:[[:space:]]*"fireworks/kimi-k2p5"' "$SETTINGS_FILE"
check "agent llm api key present" grep -Eq '"api_key"[[:space:]]*:' "$SETTINGS_FILE"
check "agent llm base url set" grep -Eq '"base_url"[[:space:]]*:[[:space:]]*"https://api.fireworks.ai/inference/v1"' "$SETTINGS_FILE"

reportResults
EOS
chmod +x "$TMP_PROJECT/test/openhands/custom_settings.sh"

devcontainer features test \
  --project-folder "$TMP_PROJECT" \
  --features openhands \
  --base-image mcr.microsoft.com/devcontainers/base:ubuntu
