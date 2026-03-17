#!/usr/bin/env bash
set -euo pipefail

V="${VERSION:-latest}"
if [ "$V" != "latest" ] && [ "$V" != "current" ]; then
  V="${V#v}"
fi

NEW_FEATURE_REF="ghcr.io/notwillk/checksy/checksy"
GHCR_REPO="notwillk/checksy/checksy"
GHCR_TAG="latest"

echo "WARNING: The ghcr.io/notwillk/devcontainer-features/checksy feature is deprecated." >&2
echo "WARNING: Use ${NEW_FEATURE_REF} instead." >&2

install_from_ghcr_feature() {
  local token_json token manifest layer_digest tmp_dir install_script

  token_json="$(curl -fsSL "https://ghcr.io/token?service=ghcr.io&scope=repository:${GHCR_REPO}:pull")"
  token="$(printf '%s' "$token_json" | sed -n 's/.*"token":"\([^"]*\)".*/\1/p')"
  if [ -z "$token" ]; then
    echo "WARNING: Unable to get anonymous GHCR token for ${NEW_FEATURE_REF}." >&2
    return 1
  fi

  manifest="$(curl -fsSL \
    -H "Authorization: Bearer ${token}" \
    -H "Accept: application/vnd.oci.image.manifest.v1+json" \
    "https://ghcr.io/v2/${GHCR_REPO}/manifests/${GHCR_TAG}")"
  layer_digest="$(printf '%s' "$manifest" | tr -d '\n' | sed -n 's/.*"layers":\[[^]]*"digest":"\([^"]*\)".*/\1/p')"
  if [ -z "$layer_digest" ]; then
    echo "WARNING: Unable to resolve layer digest for ${NEW_FEATURE_REF}:${GHCR_TAG}." >&2
    return 1
  fi

  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "$tmp_dir"' RETURN

  curl -fsSL \
    -H "Authorization: Bearer ${token}" \
    "https://ghcr.io/v2/${GHCR_REPO}/blobs/${layer_digest}" \
    -o "${tmp_dir}/feature-layer.tar"

  if ! tar -xf "${tmp_dir}/feature-layer.tar" -C "${tmp_dir}" 2>/dev/null; then
    tar -xzf "${tmp_dir}/feature-layer.tar" -C "${tmp_dir}"
  fi

  install_script="${tmp_dir}/install.sh"
  if [ ! -f "$install_script" ] && [ -f "${tmp_dir}/devcontainer-feature/install.sh" ]; then
    install_script="${tmp_dir}/devcontainer-feature/install.sh"
  fi
  if [ ! -f "$install_script" ]; then
    echo "WARNING: Downloaded ${NEW_FEATURE_REF} but did not find install.sh." >&2
    return 1
  fi

  chmod +x "$install_script"
  VERSION="$V" "$install_script"
}

if ! install_from_ghcr_feature; then
  echo "WARNING: Falling back to legacy checksy installer script." >&2
  curl -fsSL https://raw.githubusercontent.com/notwillk/checksy/main/scripts/install.sh | CHECKSY_VERSION="$V" bash
fi

checksy --version || true
