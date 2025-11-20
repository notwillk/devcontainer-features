#!/usr/bin/env bash
set -euo pipefail

V="${VERSION:-latest}"

npm install -g turbo@"$V"
