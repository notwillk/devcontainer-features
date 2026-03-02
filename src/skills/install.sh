#!/usr/bin/env bash
set -euo pipefail

SKILLS_LIST="${SKILLS:-}"

npm install -g skills

if [ -z "$SKILLS_LIST" ]; then
  echo "No skills specified, skipping skills add."
  exit 0
fi

# Determine the target user and their home directory
TARGET_USER="${_REMOTE_USER:-root}"
if [ "$TARGET_USER" = "root" ]; then
  USER_HOME="/root"
else
  USER_HOME="/home/$TARGET_USER"
fi

IFS=',' read -ra SKILL_ENTRIES <<< "$SKILLS_LIST"
for skill in "${SKILL_ENTRIES[@]}"; do
  skill="$(echo "$skill" | tr -d '[:space:]')"
  [ -z "$skill" ] && continue
  echo "Adding skill: $skill"
  if [ "$TARGET_USER" = "root" ]; then
    HOME="$USER_HOME" DISABLE_TELEMETRY=1 skills add --global --copy "$skill"
  else
    su - "$TARGET_USER" -c "DISABLE_TELEMETRY=1 skills add --global --copy $(printf '%q' "$skill")"
  fi
done
