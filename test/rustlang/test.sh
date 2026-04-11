#!/usr/bin/env bash
set -euo pipefail

source dev-container-features-test-lib

check "rustc present" rustc --version
check "cargo present" cargo --version
check "rustc version looks like semver" bash -c "rustc --version | grep -Eq '^rustc [0-9]+\.[0-9]+\.[0-9]+'"

reportResults