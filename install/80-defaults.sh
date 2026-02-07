#!/usr/bin/env bash
set -euo pipefail

echo "Creating default home directories"
DEFAULT_DIRS=(
  Notes
  Projects
  Work
)
mkdir -p "$HOME"/"${DEFAULT_DIRS[@]}"
