#!/usr/bin/env bash
# Install the tools required by the action (gh, jq, md5sum, unzip, terraform) if missing.
set -euo pipefail

BIN="$HOME/.local/tfviapr-bin"
mkdir -p "$BIN"
export PATH="$BIN:$PATH"
echo "$BIN" >> "$GITHUB_PATH"

SUDO=""
if [ "$(id -u)" != "0" ] && command -v sudo >/dev/null 2>&1; then SUDO="sudo"; fi

case "$(uname -m)" in
  x86_64|amd64) ARCH=amd64 ;;
  aarch64|arm64) ARCH=arm64 ;;
  *) echo "Unsupported arch $(uname -m)"; exit 1 ;;
esac

missing_pkgs=()
command -v unzip >/dev/null 2>&1 || missing_pkgs+=(unzip)
command -v jq >/dev/null 2>&1 || missing_pkgs+=(jq)
command -v curl >/dev/null 2>&1 || missing_pkgs+=(curl)
if [ ${#missing_pkgs[@]} -gt 0 ]; then
  $SUDO apt-get update -y
  $SUDO apt-get install -y "${missing_pkgs[@]}"
fi

TMP="$(mktemp -d)"

if ! command -v terraform >/dev/null 2>&1; then
  TF_VERSION="1.9.8"
  curl -fsSL "https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_${ARCH}.zip" -o "$TMP/terraform.zip"
  unzip -o "$TMP/terraform.zip" -d "$TMP/tf"
  install -m 0755 "$TMP/tf/terraform" "$BIN/terraform"
fi

if ! command -v gh >/dev/null 2>&1; then
  GH_VERSION="2.62.0"
  curl -fsSL "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_${ARCH}.tar.gz" -o "$TMP/gh.tar.gz"
  tar -xzf "$TMP/gh.tar.gz" -C "$TMP"
  install -m 0755 "$TMP/gh_${GH_VERSION}_linux_${ARCH}/bin/gh" "$BIN/gh"
fi

rm -rf "$TMP"
terraform version
gh --version
jq --version
command -v md5sum
command -v unzip
