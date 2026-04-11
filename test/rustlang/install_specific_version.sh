#!/usr/bin/env bash
set -euo pipefail

source dev-container-features-test-lib

check "rustc present" rustc --version
check "cargo present" cargo --version
check "rustc matches requested version" bash -c "rustc --version | grep -Eq '^rustc 1\.85\.0'"

reportResults