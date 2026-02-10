#!/bin/bash

# Restart dbus
# sudo systemctl --user restart dbus || true

# Add daemons to niri-service
sudo -u "$COFFEE_DEFAULT_USER" systemctl --user add-wants niri.service waybar.service
sudo -u "$COFFEE_DEFAULT_USER" systemctl --user add-wants niri.service mako.service
sudo -u "$COFFEE_DEFAULT_USER" systemctl --user add-wants niri.service swaybg.service
sudo -u "$COFFEE_DEFAULT_USER" systemctl --user add-wants niri.service swayidle.service
sudo -u "$COFFEE_DEFAULT_USER" systemctl --user add-wants niri.service swayosd.service

# Reload user daemons
sudo -u "$COFFEE_DEFAULT_USER" systemctl --user daemon-reload
