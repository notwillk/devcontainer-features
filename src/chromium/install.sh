#!/usr/bin/env bash
set -euo pipefail

echo "Installing Chromium launcher wrappers..."

IMAGE_DEFAULT="${IMAGE:-ghcr.io/puppeteer/puppeteer:latest}"
PLATFORM_DEFAULT="${PLATFORM:-linux/amd64}"
SANDBOX_DEFAULT="${SANDBOX:-off}"

case "${SANDBOX_DEFAULT}" in
  on|off)
    ;;
  *)
    echo "ERROR: sandbox option must be 'on' or 'off'." >&2
    exit 1
    ;;
esac

if [ "$(id -u)" -ne 0 ]; then
  echo "ERROR: install.sh must be run as root." >&2
  exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: docker CLI not found. Add a Docker feature such as docker-in-docker." >&2
  exit 1
fi

cat >/usr/local/bin/chromium <<EOF_INNER
#!/usr/bin/env bash
set -euo pipefail

IMAGE="\${PUPPETEER_IMAGE:-${IMAGE_DEFAULT}}"
PLATFORM="\${PUPPETEER_PLATFORM:-${PLATFORM_DEFAULT}}"
SANDBOX="\${PUPPETEER_SANDBOX:-${SANDBOX_DEFAULT}}"

if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: docker CLI not found. Install a Docker feature (for example docker-in-docker)." >&2
  exit 1
fi

DOCKER_ARGS=(run --rm -i --init -v "\${PWD}:\${PWD}" -w "\${PWD}" -v /tmp:/tmp)
if [ -n "\${PLATFORM}" ]; then
  DOCKER_ARGS+=(--platform="\${PLATFORM}")
fi

case "\${SANDBOX}" in
  on)
    SANDBOX_ARGS=()
    ;;
  off)
    SANDBOX_ARGS=(--no-sandbox --disable-setuid-sandbox)
    ;;
  *)
    echo "ERROR: PUPPETEER_SANDBOX must be 'on' or 'off'." >&2
    exit 2
    ;;
esac

exec docker "\${DOCKER_ARGS[@]}" "\${IMAGE}" bash -lc 'BROWSER_BIN="\$(command -v google-chrome-stable || command -v google-chrome || command -v chromium-browser || command -v chromium || true)"; if [ -z "\${BROWSER_BIN}" ]; then BROWSER_BIN="\$(find /home/pptruser/.cache/puppeteer/chrome /root/.cache/puppeteer/chrome -type f \( -name chrome -o -name chrome-wrapper \) -print -quit 2>/dev/null || true)"; fi; if [ -z "\${BROWSER_BIN}" ]; then echo "ERROR: no Chrome/Chromium binary found in container image." >&2; exit 127; fi; exec "\${BROWSER_BIN}" "\$@"' -- "\${SANDBOX_ARGS[@]}" "\$@"
EOF_INNER
chmod +x /usr/local/bin/chromium

cat >/usr/local/bin/chromium-headless <<EOF_INNER
#!/usr/bin/env bash
set -euo pipefail

IMAGE="\${PUPPETEER_IMAGE:-${IMAGE_DEFAULT}}"
PLATFORM="\${PUPPETEER_PLATFORM:-${PLATFORM_DEFAULT}}"
SANDBOX="\${PUPPETEER_SANDBOX:-${SANDBOX_DEFAULT}}"

if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: docker CLI not found. Install a Docker feature (for example docker-in-docker)." >&2
  exit 1
fi

DOCKER_ARGS=(run --rm -i --init -v "\${PWD}:\${PWD}" -w "\${PWD}" -v /tmp:/tmp)
if [ -n "\${PLATFORM}" ]; then
  DOCKER_ARGS+=(--platform="\${PLATFORM}")
fi

case "\${SANDBOX}" in
  on)
    SANDBOX_ARGS=()
    ;;
  off)
    SANDBOX_ARGS=(--no-sandbox --disable-setuid-sandbox)
    ;;
  *)
    echo "ERROR: PUPPETEER_SANDBOX must be 'on' or 'off'." >&2
    exit 2
    ;;
esac

if [ "$#" -eq 0 ]; then
  set -- --dump-dom about:blank
fi

exec docker "\${DOCKER_ARGS[@]}" "\${IMAGE}" bash -lc 'BROWSER_BIN="\$(command -v google-chrome-stable || command -v google-chrome || command -v chromium-browser || command -v chromium || true)"; if [ -z "\${BROWSER_BIN}" ]; then BROWSER_BIN="\$(find /home/pptruser/.cache/puppeteer/chrome /root/.cache/puppeteer/chrome -type f \( -name chrome -o -name chrome-wrapper \) -print -quit 2>/dev/null || true)"; fi; if [ -z "\${BROWSER_BIN}" ]; then echo "ERROR: no Chrome/Chromium binary found in container image." >&2; exit 127; fi; exec env DBUS_SESSION_BUS_ADDRESS=/dev/null "\${BROWSER_BIN}" --headless=new --disable-dev-shm-usage "\$@" 2>/dev/null' -- "\${SANDBOX_ARGS[@]}" "\$@"
EOF_INNER
chmod +x /usr/local/bin/chromium-headless

echo "Installed launchers:"
echo "  - /usr/local/bin/chromium"
echo "  - /usr/local/bin/chromium-headless"
echo "Defaults:"
echo "  - image: ${IMAGE_DEFAULT}"
echo "  - platform: ${PLATFORM_DEFAULT:-<none>}"
echo "  - sandbox: ${SANDBOX_DEFAULT}"
