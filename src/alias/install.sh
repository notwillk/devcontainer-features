#!/usr/bin/env bash
set -euo pipefail

NAME="${NAME:?NAME option is required}"
EXEC="${EXEC:?EXEC option is required}"

if command -v "$NAME" >/dev/null 2>&1; then
  echo "Command '$NAME' already exists at $(command -v "$NAME")" >&2
  exit 1
fi

install_dir="/usr/local/bin"
target="${install_dir}/${NAME}"

mkdir -p "$install_dir"
cat <<EOF >"$target"
#!/usr/bin/env bash
set -euo pipefail
exec $EXEC "\$@"
EOF
chmod +x "$target"
