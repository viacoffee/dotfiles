#!/usr/bin/env bash
# Composable helpers for niri window management
# Intended to be sourced, not executed

set -euo pipefail

# Prevent accidental execution
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  echo "This file is meant to be sourced, not executed."
  exit 1
fi

niri_is_overview_open() {
  niri msg --json overview-state |
    jq -e '.is_open' > /dev/null
}

niri_is_window_focused() {
  local window_id="$1"

  _niri_windows_json |
    jq -e --argjson wid "$window_id" '
      any(.id == $wid and .is_focused)
    ' > /dev/null
}

# -------------------------------------------------------------------
# Internal helpers
# -------------------------------------------------------------------

# Fetch window JSON snapshot
_niri_windows_json() {
  niri msg --json windows
}

# Message action to each window ID
# Usage: _niri_message_to_ids <action>
_niri_message_to_ids() {
  local action="$1"
  shift
  while read -r id; do
    niri msg action "$action" --id "$id"
  done
}

# -------------------------------------------------------------------
# Query primitives
# -------------------------------------------------------------------

# Return full window JSON snapshot
niri_windows() {
  _niri_windows_json
}

# Return the ID of the focused window
niri_focused_window_id() {
  _niri_windows_json |
    jq -r '.[] | select(.is_focused) | .id'
}

# Return the workspace ID of the focused window
niri_focused_workspace_id() {
  _niri_windows_json |
    jq -r '.[] | select(.is_focused) | .workspace_id'
}

# Return IDs of all windows on a specific workspace
niri_windows_on_workspace() {
  local workspace_id="$1"
  _niri_windows_json |
    jq -r --arg ws "$workspace_id" '.[] | select(.workspace_id == $ws) | .id'
}

# Return windows matching a pattern in app_id or title
niri_windows_matching() {
  local pattern="$1"

  if [ -t 0 ]; then
    _niri_windows_json
  else
    cat
  fi |
    jq -r --arg p "$pattern" '
      [
        .[]
        | select(
          (.app_id // "" | test($p; "i")) or
          (.title  // "" | test($p; "i"))
        )
      ]
    '
}

# Return IDs of all unfocused windows
niri_unfocused_window_ids() {
  jq -r '. | select(.is_focused | not) | .id'
}

# Return all windows on the currently focused workspace
niri_windows_on_focused_workspace() {
  _niri_windows_json |
    jq -r '
      . as $windows
      | $windows[]
      | select(.is_focused)
      | .workspace_id
      as $ws
      | $windows[]
      | select(.workspace_id == $ws)
    '
}

# -------------------------------------------------------------------
# Window actions
# -------------------------------------------------------------------

# Close all windows
niri_close_all_windows() {
  _niri_windows_json |
    jq -r '.[].id' |
    _niri_message_to_ids close-window
}

# Close all windows on the focused workspace
niri_close_all_on_focused_workspace() {
  _niri_windows_json |
    niri_windows_on_focused_workspace |
    _niri_message_to_ids close-window
}

# Close all windows except the focused window (on its workspace)
niri_close_all_unfocused_on_workspace() {
  niri_windows_on_focused_workspace |
    niri_unfocused_window_ids |
    _niri_message_to_ids close-window
}

# Close all windows matching a pattern
niri_close_matching() {
  local pattern="$1"
  _niri_windows_json |
    niri_windows_matching "$pattern" |
    _niri_message_to_ids close-window
}

# Focus or spawn window
niri_focus_or_spawn() {
  local pattern="$1"
  shift

  local window_id
  window_id="$(
    _niri_windows_json |
      jq -r --arg p "$pattern" '
        first(
          .[]
          | select(
              (.app_id // "" | test($p; "i")) or
              (.title  // "" | test($p; "i"))
            )
        ).id // empty
      '
  )"

  if [[ -n "$window_id" ]]; then
    # Focus existing window
    _niri_message_to_ids <<<$window_id focus-window
  else
    # Spawn the app if no window found
    "$@" &
  fi
}
