#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Include niri helpers
source "$SCRIPT_DIR/includes/niri-helpers.sh"

# Gracefully close all niri-managed windows
niri_close_all_windows || true

# Give slow apps a moment to exit cleanly
sleep 1

# Power off without broadcasting to other users
systemctl poweroff --no-wall
