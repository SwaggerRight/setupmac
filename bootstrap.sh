#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

echo "Installing Ansible collections..."
ansible-galaxy collection install --upgrade -r "${SCRIPT_DIR}/requirements.yml"

echo "Running the setup playbook..."
ansible-playbook \
  -i "${SCRIPT_DIR}/inventory.yml" \
  "${SCRIPT_DIR}/playbook.yml" \
  "$@"
