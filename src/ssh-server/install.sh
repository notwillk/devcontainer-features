#!/usr/bin/env bash
set -euo pipefail

PORT="${PORT:-22}"
TARGET_USER="${_REMOTE_USER:-root}"
TARGET_HOME="${_REMOTE_USER_HOME:-}"
INSTALL_DIR="/usr/local/share/devcontainer-ssh-server"
CONFIG_FILE="$INSTALL_DIR/config.env"
SSHD_CONFIG_DIR="/etc/ssh/sshd_config.d"
SSHD_CONFIG_FILE="$SSHD_CONFIG_DIR/99-devcontainer-ssh-server.conf"
SUDOERS_FILE="/etc/sudoers.d/devcontainer-ssh-server"

if ! [[ "$PORT" =~ ^[0-9]+$ ]] || [ "$PORT" -lt 1 ] || [ "$PORT" -gt 65535 ]; then
  echo "Invalid SSH port: $PORT" >&2
  exit 1
fi

if [[ "$TARGET_USER" =~ [[:space:]] ]]; then
  echo "Remote user must not contain whitespace: $TARGET_USER" >&2
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y openssh-server openssh-client procps sudo
rm -rf /var/lib/apt/lists/*

if [ -z "$TARGET_HOME" ]; then
  if getent passwd "$TARGET_USER" >/dev/null 2>&1; then
    TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
  elif [ "$TARGET_USER" = "root" ]; then
    TARGET_HOME="/root"
  else
    TARGET_HOME="/home/$TARGET_USER"
  fi
fi

mkdir -p "$INSTALL_DIR" "$SSHD_CONFIG_DIR" /run/sshd

printf 'TARGET_USER=%q\n' "$TARGET_USER" > "$CONFIG_FILE"
printf 'TARGET_HOME=%q\n' "$TARGET_HOME" >> "$CONFIG_FILE"
printf 'SSH_PORT=%q\n' "$PORT" >> "$CONFIG_FILE"
chmod 0644 "$CONFIG_FILE"

if ! grep -Eq '^[[:space:]]*Include[[:space:]]+/etc/ssh/sshd_config\.d/\*\.conf' /etc/ssh/sshd_config; then
  tmp_config="$(mktemp)"
  {
    echo "Include /etc/ssh/sshd_config.d/*.conf"
    cat /etc/ssh/sshd_config
  } > "$tmp_config"
  cat "$tmp_config" > /etc/ssh/sshd_config
  rm -f "$tmp_config"
fi

cat > "$SSHD_CONFIG_FILE" <<EOF
Port $PORT
PubkeyAuthentication yes
PasswordAuthentication no
KbdInteractiveAuthentication no
ChallengeResponseAuthentication no
PermitEmptyPasswords no
PermitRootLogin prohibit-password
AuthorizedKeysFile .ssh/authorized_keys .ssh/authorized_keys.d/devcontainer-ssh-server
AllowUsers $TARGET_USER
EOF
chmod 0644 "$SSHD_CONFIG_FILE"

cat > "$INSTALL_DIR/start.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="/usr/local/share/devcontainer-ssh-server/config.env"

if [ -f "$CONFIG_FILE" ]; then
  # shellcheck source=/dev/null
  source "$CONFIG_FILE"
fi

TARGET_USER="${TARGET_USER:-${_REMOTE_USER:-root}}"
TARGET_HOME="${TARGET_HOME:-${_REMOTE_USER_HOME:-}}"
SSH_PORT="${SSH_PORT:-22}"

if ! id "$TARGET_USER" >/dev/null 2>&1; then
  echo "Remote user '$TARGET_USER' does not exist; cannot configure SSH login." >&2
  exit 1
fi

if [ -z "$TARGET_HOME" ]; then
  TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
fi

TARGET_GROUP="$(id -gn "$TARGET_USER")"
SSH_DIR="$TARGET_HOME/.ssh"
AUTHORIZED_KEYS_DIR="$SSH_DIR/authorized_keys.d"
MANAGED_KEYS_FILE="$AUTHORIZED_KEYS_DIR/devcontainer-ssh-server"

install -d -m 0700 -o "$TARGET_USER" -g "$TARGET_GROUP" "$SSH_DIR" "$AUTHORIZED_KEYS_DIR"

if [ -n "${SSH_PUBLIC_KEY:-}" ]; then
  tmp_keys="$(mktemp)"
  printf '%s\n' "$SSH_PUBLIC_KEY" | sed 's/\r$//' | awk 'NF { print }' > "$tmp_keys"
  if [ -s "$tmp_keys" ]; then
    install -m 0600 -o "$TARGET_USER" -g "$TARGET_GROUP" "$tmp_keys" "$MANAGED_KEYS_FILE"
  else
    rm -f "$MANAGED_KEYS_FILE"
  fi
  rm -f "$tmp_keys"
else
  rm -f "$MANAGED_KEYS_FILE"
fi

install -d -m 0755 /run/sshd
ssh-keygen -A
/usr/sbin/sshd -t

if command -v systemctl >/dev/null 2>&1 && [ -d /run/systemd/system ]; then
  systemctl enable ssh >/dev/null 2>&1 || true
  if systemctl restart ssh >/dev/null 2>&1 || systemctl restart sshd >/dev/null 2>&1; then
    exit 0
  fi
fi

if command -v service >/dev/null 2>&1; then
  if service ssh restart >/dev/null 2>&1 || service ssh start >/dev/null 2>&1; then
    exit 0
  fi
fi

if pgrep -x sshd >/dev/null 2>&1; then
  pkill -HUP -x sshd || true
else
  /usr/sbin/sshd
fi

if ! pgrep -x sshd >/dev/null 2>&1; then
  echo "sshd did not start on port $SSH_PORT" >&2
  exit 1
fi
EOF
chmod 0755 "$INSTALL_DIR/start.sh"

if [ "$TARGET_USER" != "root" ]; then
  if ! id "$TARGET_USER" >/dev/null 2>&1; then
    echo "Remote user '$TARGET_USER' does not exist; cannot configure sudo for SSH startup." >&2
    exit 1
  fi

  cat > "$SUDOERS_FILE" <<EOF
$TARGET_USER ALL=(root) NOPASSWD:SETENV: $INSTALL_DIR/start.sh
EOF
  chmod 0440 "$SUDOERS_FILE"
  visudo -cf "$SUDOERS_FILE"
fi

/usr/sbin/sshd -t
