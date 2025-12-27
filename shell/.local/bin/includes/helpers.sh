#!/bin/bash

# Set to 0 to disable notifications
: "${NOTIFY_ENABLED:=1}"

signal_waybar() {
    if [ -n "$1" ]; then
        pkill -RTMIN+$1 waybar
    fi
}

_notify_available() {
    command -v notify-send >/dev/null \
        && [[ -n "${DISPLAY:-}" || -n "${WAYLAND_DISPLAY:-}" ]]
}

notify() {
    local urgency="normal"
    local message

    # Optional urgency flag
    if [[ "$1" == "-u" ]]; then
        urgency="$2"
        shift 2
    fi

    message="$*"

    [[ "$NOTIFY_ENABLED" -eq 1 ]] || return 0
    _notify_available || return 0

    notify-send -u "$urgency" "$message"
}

notify_err() {
    notify -u critical "$@"
}
