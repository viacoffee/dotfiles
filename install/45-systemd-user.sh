#!/usr/bin/env bash
set -euo pipefail

systemctl --user import-environment \
  DISPLAY \
  WAYLAND_DISPLAY \
  XDG_CURRENT_DESKTOP \
  XDG_SESSION_TYPE

# Restart dbus
systemctl --user restart dbus || true

# Reload daemons
systemctl --user daemon-reload

# Add daemons to niri-service
systemctl --user add-wants niri.service waybar.service
systemctl --user add-wants niri.service mako.service
systemctl --user add-wants niri.service swaybg.service
systemctl --user add-wants niri.service swayidle.service
