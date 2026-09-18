#!/usr/bin/env bash

set -uo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This inventory script must be run on macOS." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
OUTPUT_DIR="${1:-${REPO_ROOT}/inventory-output/${TIMESTAMP}}"

mkdir -p "${OUTPUT_DIR}/defaults"

run_capture() {
  local output_file="$1"
  shift

  if command -v "$1" >/dev/null 2>&1; then
    "$@" >"${OUTPUT_DIR}/${output_file}" 2>&1 || true
  else
    printf '%s is not installed.\n' "$1" >"${OUTPUT_DIR}/${output_file}"
  fi
}

echo "Collecting Mac inventory in ${OUTPUT_DIR}"

{
  echo "Collected: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "Computer name: $(scutil --get ComputerName 2>/dev/null || true)"
  echo "Architecture: $(uname -m)"
  sw_vers
} >"${OUTPUT_DIR}/system.txt"

system_profiler SPHardwareDataType >"${OUTPUT_DIR}/hardware.txt" 2>&1 || true
system_profiler SPApplicationsDataType >"${OUTPUT_DIR}/applications.txt" 2>&1 || true

find /Applications "${HOME}/Applications" -maxdepth 1 -name '*.app' -print 2>/dev/null \
  | sort >"${OUTPUT_DIR}/applications-list.txt"

{
  printf 'application\tarchitectures\n'
  while IFS= read -r application; do
    architectures="$(mdls -raw -name kMDItemExecutableArchitectures "${application}" 2>/dev/null || true)"
    printf '%s\t%s\n' "${application}" "${architectures//$'\n'/ }"
  done <"${OUTPUT_DIR}/applications-list.txt"
} >"${OUTPUT_DIR}/application-architectures.tsv"

awk -F '\t' 'NR == 1 || ($2 ~ /x86_64/ && $2 !~ /arm64/)' \
  "${OUTPUT_DIR}/application-architectures.tsv" \
  >"${OUTPUT_DIR}/intel-only-applications.tsv"

if command -v brew >/dev/null 2>&1; then
  brew config >"${OUTPUT_DIR}/brew-config.txt" 2>&1 || true
  brew tap >"${OUTPUT_DIR}/brew-taps.txt" 2>&1 || true
  brew leaves >"${OUTPUT_DIR}/brew-formulae.txt" 2>&1 || true
  brew list --cask >"${OUTPUT_DIR}/brew-casks.txt" 2>&1 || true
  brew bundle dump --file="${OUTPUT_DIR}/Brewfile" --force 2>&1 \
    | tee "${OUTPUT_DIR}/brew-bundle.log" >/dev/null || true
else
  echo "Homebrew is not installed." >"${OUTPUT_DIR}/brew-status.txt"
fi

run_capture "mas-apps.txt" mas list
run_capture "vscode-extensions.txt" code --list-extensions --show-versions
run_capture "powershell-modules.txt" pwsh -NoProfile -Command \
  'Get-Module -ListAvailable | Sort-Object Name,Version | Select-Object Name,Version,Path | Format-Table -AutoSize'
run_capture "python-user-packages.txt" python3 -m pip list --user
run_capture "npm-global-packages.txt" npm list --global --depth=0

git config --global --list --show-origin >"${OUTPUT_DIR}/git-config.txt" 2>&1 || true
printf '%s\n' "${SHELL:-unknown}" >"${OUTPUT_DIR}/shell.txt"
dscl . -read "/Users/${USER}" UserShell >>"${OUTPUT_DIR}/shell.txt" 2>&1 || true

defaults export NSGlobalDomain "${OUTPUT_DIR}/defaults/global.plist" 2>/dev/null || true
defaults export com.apple.finder "${OUTPUT_DIR}/defaults/finder.plist" 2>/dev/null || true
defaults export com.apple.dock "${OUTPUT_DIR}/defaults/dock.plist" 2>/dev/null || true

osascript -e 'tell application "System Events" to get the name of every login item' \
  >"${OUTPUT_DIR}/login-items.txt" 2>&1 || true

find "${HOME}/Library/LaunchAgents" /Library/LaunchAgents /Library/LaunchDaemons \
  -maxdepth 1 -name '*.plist' -print 2>/dev/null | sort \
  >"${OUTPUT_DIR}/launch-agents-and-daemons.txt"

if [[ -f "${HOME}/.ssh/config" ]]; then
  awk '
    /^[[:space:]]*Host[[:space:]]+/ { print }
    /^[[:space:]]*Include[[:space:]]+/ { print }
  ' "${HOME}/.ssh/config" >"${OUTPUT_DIR}/ssh-config-structure.txt"
else
  echo "No ~/.ssh/config file found." >"${OUTPUT_DIR}/ssh-config-structure.txt"
fi

cat >"${OUTPUT_DIR}/REVIEW-ME.md" <<'EOF'
# Inventory review checklist

This directory is intentionally excluded from Git. Review it locally before
copying any values into the playbook.

- Review `intel-only-applications.tsv`; replace those applications with native
  Apple Silicon versions when possible before deciding whether Rosetta is needed.
- Remove applications and packages you no longer use.
- Classify software as Homebrew, App Store, MDM, vendor installer, or manual.
- Choose only the macOS preferences you intentionally want to manage.
- Check output for usernames, email addresses, internal paths, hostnames, or
  other information you do not want committed.
- Never commit private keys, tokens, passwords, certificates, browser data,
  or cloud credential files.
EOF

echo "Inventory complete. Review ${OUTPUT_DIR}/REVIEW-ME.md before sharing output."
