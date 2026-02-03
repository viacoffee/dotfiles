#!/usr/bin/env bash
# Intended to be sourced, not executed

set -euo pipefail

# Prevent accidental execution
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  echo "This file is meant to be sourced, not executed."
  exit 1
fi

# -------------------------------------------------------------------
# Helpers
# -------------------------------------------------------------------

niri_windows() {
  niri msg windows -j
}

niri_focused_window_id() {
  niri_windows | jq -r '.[] | select(.focused) | .id'
}

niri_windows_matching() {
  local pattern="$1"

  niri_windows |
    jq -r --arg p "$pattern" '
      .[]
      | select(
          (.app_id // "" | test($p; "i")) or
          (.title  // "" | test($p; "i"))
        )
      | .id
    '
}

# -------------------------------------------------------------------
# Window actions
# -------------------------------------------------------------------

niri_close_all_windows() {
  niri_windows | jq -r '.[].id' |
    while read -r id; do
      niri msg close-window --id "$id"
    done
}

niri_close_all_but_focused() {
  local focused_id
  focused_id="$(niri_focused_window_id)"

  [[ -z "${focused_id:-}" ]] && return 0

  niri_windows |
    jq -r --arg fid "$focused_id" '.[] | select(.id != $fid) | .id' |
    while read -r id; do
      niri msg close-window --id "$id"
    done
}
