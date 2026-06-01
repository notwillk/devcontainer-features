#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP_PROJECT="$(mktemp -d)"
trap 'rm -rf "$TMP_PROJECT"' EXIT

cp -R "$PROJECT_ROOT/src" "$TMP_PROJECT/src"
mkdir -p "$TMP_PROJECT/test/ssh-server"

cat >"$TMP_PROJECT/test/ssh-server/test.sh" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=/dev/null
source dev-container-features-test-lib

check "sshd available" test -x /usr/sbin/sshd
check "ssh available" ssh -V
check "sshd config validates" sudo /usr/sbin/sshd -t
check "startup script exists" test -x /usr/local/share/devcontainer-ssh-server/start.sh
check "sshd is running after postStart" pgrep -x sshd
check "managed key absent without SSH_PUBLIC_KEY" test ! -e /home/vscode/.ssh/authorized_keys.d/devcontainer-ssh-server

reportResults
EOS
chmod +x "$TMP_PROJECT/test/ssh-server/test.sh"

cat >"$TMP_PROJECT/test/ssh-server/scenarios.json" <<'EOS'
{
  "with_public_key": {
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "remoteUser": "vscode",
    "features": {
      "ssh-server": {
        "port": "22"
      }
    },
    "containerEnv": {
      "SSH_PUBLIC_KEY": "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICUvv81/AHvhhQAlPCPJZmdFqdph3EQnlteqPDVpnj3q devcontainer-ssh-server-test"
    }
  }
}
EOS

cat >"$TMP_PROJECT/test/ssh-server/with_public_key.sh" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=/dev/null
source dev-container-features-test-lib

TEST_KEY="/tmp/devcontainer-ssh-server-test-key"
KNOWN_HOSTS="/tmp/devcontainer-ssh-server-known-hosts"

cat > "$TEST_KEY" <<'KEY'
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
QyNTUxOQAAACAlL7/NfwB74YUAJTwjyWZnRanaYdxEJ5bXqjw1aZ496gAAAKCeCZGtngmR
rQAAAAtzc2gtZWQyNTUxOQAAACAlL7/NfwB74YUAJTwjyWZnRanaYdxEJ5bXqjw1aZ496g
AAAECbO5rpXbSPw7nvNjHnwwB+Apy74tRy5vBE9QEOd5iDeCUvv81/AHvhhQAlPCPJZmdF
qdph3EQnlteqPDVpnj3qAAAAHGRldmNvbnRhaW5lci1zc2gtc2VydmVyLXRlc3QB
-----END OPENSSH PRIVATE KEY-----
KEY
chmod 0600 "$TEST_KEY"

check "managed key installed for vscode" grep -F "devcontainer-ssh-server-test" /home/vscode/.ssh/authorized_keys.d/devcontainer-ssh-server
check "managed key owned by vscode" bash -lc "stat -c '%U:%G %a' /home/vscode/.ssh/authorized_keys.d/devcontainer-ssh-server | grep -Fx 'vscode:vscode 600'"
check "sshd is running" pgrep -x sshd
check "ssh login reaches vscode" bash -lc "ssh -i '$TEST_KEY' -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile='$KNOWN_HOSTS' -p 22 vscode@127.0.0.1 whoami | grep -Fx vscode"

reportResults
EOS
chmod +x "$TMP_PROJECT/test/ssh-server/with_public_key.sh"

devcontainer features test \
  --project-folder "$TMP_PROJECT" \
  --features ssh-server \
  --base-image mcr.microsoft.com/devcontainers/base:ubuntu \
  --remote-user vscode
