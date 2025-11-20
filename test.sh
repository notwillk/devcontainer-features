#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"

mapfile -t TEST_SCRIPTS < <(find "$ROOT/src" -type f -name test.sh | sort)

if [ ${#TEST_SCRIPTS[@]} -eq 0 ]; then
  echo "No test.sh scripts found under src/" >&2
  exit 1
fi

status=0
failed=()
for script in "${TEST_SCRIPTS[@]}"; do
  rel="${script#$ROOT/}"
  echo ">>> Running ${rel}"
  if ! bash "$script"; then
    echo "!!! Failed: ${rel}" >&2
    failed+=("$rel")
    status=1
  fi
done

if [ "$status" -ne 0 ]; then
  echo
  echo "Failed feature tests:"
  for feature in "${failed[@]}"; do
    echo "  - $feature"
  done
fi

exit "$status"
