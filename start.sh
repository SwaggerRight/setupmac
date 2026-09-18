#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "start.sh is retained for compatibility; using bootstrap.sh."
exec "${SCRIPT_DIR}/bootstrap.sh" "$@"
