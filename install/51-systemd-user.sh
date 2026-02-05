#!/usr/bin/env bash
set -euo pipefail

# Restart dbus
systemctl --user restart dbus || true

# Add daemons to niri-service
systemctl --user add-wants niri.service waybar.service
systemctl --user add-wants niri.service mako.service
systemctl --user add-wants niri.service swaybg.service
systemctl --user add-wants niri.service swayidle.service

# Add niri-service
systemctl --user enable niri.service

# Reload daemons
systemctl --user daemon-reload
