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
  [ "$(niri msg overview-state)" != "Overview is closed." ]
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
    niri msg "$action" --id "$id"
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
    jq -r '.[] | select(.focused) | .id'
}

# Return the workspace ID of the focused window
niri_focused_workspace_id() {
  _niri_windows_json |
    jq -r '.[] | select(.focused) | .workspace_id'
}

# Return IDs of all windows on a specific workspace
niri_windows_on_workspace() {
  local workspace_id="$1"
  jq -r --arg ws "$workspace_id" '.[] | select(.workspace_id == $ws) | .id'
}

# Return IDs of all windows matching a pattern in app_id or title
niri_windows_matching() {
  local pattern="$1"
  jq -r --arg p "$pattern" '
    .[]
    | select(
        (.app_id // "" | test($p; "i")) or
        (.title  // "" | test($p; "i"))
      )
    | .id
  '
}

# Return IDs of all unfocused windows
niri_windows_unfocused() {
  jq -r '.[] | select(.focused | not) | .id'
}

# Return IDs of all windows on the currently focused workspace
niri_windows_on_focused_workspace() {
  jq -r '
    . as $windows
    | $windows[]
    | select(.focused)
    | .workspace_id
    as $ws
    | $windows[]
    | select(.workspace_id == $ws)
    | .id
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
niri_close_all_but_focused() {
  _niri_windows_json |
    niri_windows_on_focused_workspace |
    niri_windows_unfocused |
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
  local launch_cmd="${2:-$pattern}"
  local windows
  local window_id

  # Take a single snapshot
  windows="$(_niri_windows_json)"

  # Look for first matching window
  window_id="$(
    echo "$windows" |
      niri_windows_matching "$pattern" |
      head -n1
  )"

  if [[ -n "$window_id" ]]; then
    # Focus existing window
    _niri_message_to_ids focus-window <<<"$window_id"
  else
    # Spawn the app if no window found
    eval "$launch_cmd" &
  fi
}
