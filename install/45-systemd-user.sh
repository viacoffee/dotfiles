#!/usr/bin/env bash
set -euo pipefail

systemctl --user import-environment \
  DISPLAY \
  WAYLAND_DISPLAY \
  XDG_CURRENT_DESKTOP \
  XDG_SESSION_TYPE

systemctl --user restart dbus || true
