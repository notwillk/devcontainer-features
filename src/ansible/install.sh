#!/usr/bin/env bash
set -euo pipefail

SUDO=""
if [ "$(id -u)" -ne 0 ]; then
  SUDO="sudo"
fi

export DEBIAN_FRONTEND=noninteractive

$SUDO apt-get update
$SUDO apt-get install -y --no-install-recommends ansible
$SUDO rm -rf /var/lib/apt/lists/*

command -v ansible
ansible --version
command -v ansible-playbook
ansible-playbook --version

echo "ansible installation complete"
