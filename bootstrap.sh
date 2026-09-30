#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_OPTIONAL=false
INSTALL_VIRTUALIZATION=false
INSTALL_APP_STORE=false
INSTALL_ROSETTA=false
ANSIBLE_ARGS=()

usage() {
  cat <<'EOF'
Usage: ./bootstrap.sh [profile options] [ansible-playbook options]

Profile options:
  --with-optional        Install Brewfile.optional
  --with-virtualization  Install Brewfile.virtualization
  --with-app-store       Install Brewfile.mas (requires App Store sign-in)
  --with-rosetta         Install Brewfile.rosetta (requires Rosetta)
  -h, --help             Show this help

With no profile options, only the M5-native baseline Brewfile is applied.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --with-optional)
      INSTALL_OPTIONAL=true
      ;;
    --with-virtualization)
      INSTALL_VIRTUALIZATION=true
      ;;
    --with-app-store)
      INSTALL_APP_STORE=true
      ;;
    --with-rosetta)
      INSTALL_ROSETTA=true
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      ANSIBLE_ARGS+=("$1")
      ;;
  esac
  shift
done

apply_brewfile() {
  local brewfile_name="$1"
  echo "Applying ${brewfile_name}..."
  brew bundle install --file="${SCRIPT_DIR}/${brewfile_name}" --no-upgrade
}

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This bootstrap script must be run on macOS." >&2
  exit 1
fi

if ! xcode-select -p >/dev/null 2>&1; then
  echo "Xcode Command Line Tools are required."
  echo "Starting the installer; rerun ./bootstrap.sh after it finishes."
  xcode-select --install
  exit 1
fi

if ! command -v brew >/dev/null 2>&1; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
else
  echo "Homebrew was installed but could not be found." >&2
  exit 1
fi

echo "Installing bootstrap dependencies..."
brew install ansible git

echo "Authorizing application installers..."
sudo -v

apply_brewfile Brewfile

if [[ "${INSTALL_OPTIONAL}" == true ]]; then
  apply_brewfile Brewfile.optional
  ANSIBLE_ARGS+=("-e" "install_optional_apps=true")
fi

if [[ "${INSTALL_VIRTUALIZATION}" == true ]]; then
  apply_brewfile Brewfile.virtualization
  ANSIBLE_ARGS+=("-e" "install_virtualization_apps=true")
fi

if [[ "${INSTALL_APP_STORE}" == true ]]; then
  apply_brewfile Brewfile.mas
  ANSIBLE_ARGS+=("-e" "install_app_store_apps=true")
fi

if [[ "${INSTALL_ROSETTA}" == true ]]; then
  if [[ "$(uname -m)" == "arm64" ]] && \
    ! /usr/sbin/pkgutil --pkg-info com.apple.pkg.RosettaUpdateAuto >/dev/null 2>&1; then
    echo "Rosetta applications were requested, but Rosetta is not installed." >&2
    echo "Review docs/migration-review.md before installing it." >&2
    exit 2
  fi
  apply_brewfile Brewfile.rosetta
  ANSIBLE_ARGS+=("-e" "install_rosetta_apps=true")
fi

echo "Installing Ansible collections..."
ansible-galaxy collection install --upgrade -r "${SCRIPT_DIR}/requirements.yml"

echo "Running the setup playbook..."
ansible-playbook \
  -i "${SCRIPT_DIR}/inventory.yml" \
  "${SCRIPT_DIR}/playbook.yml" \
  "${ANSIBLE_ARGS[@]}"
