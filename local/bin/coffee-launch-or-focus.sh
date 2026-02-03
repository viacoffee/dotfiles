#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $(basename "$0") <window_pattern> [launch_command]"
  echo
  echo "Examples:"
  echo "  $(basename "$0") firefox firefox"
  echo "  $(basename "$0") alacritty alacritty"
  echo "  $(basename "$0") slack \"slack --enable-features=UseOzonePlatform --ozone-platform=wayland\""
  exit 1
fi

PATTERN="$1"
LAUNCH_COMMAND="${2:-$PATTERN}"

WINDOW_ID=$(
  niri msg windows -j |
    jq -r --arg p "$PATTERN" '
      .[]
      | select(
          (.app_id // "" | test($p; "i")) or
          (.title  // "" | test($p; "i"))
        )
      | .id
    ' | head -n1
)

if [[ -n "${WINDOW_ID:-}" ]]; then
  niri msg focus-window --id "$WINDOW_ID"
else
  niri msg spawn -- sh -c "$LAUNCH_COMMAND"
fi
