#!/bin/bash

# Restart dbus
sudo systemctl --user restart dbus || true

# Add daemons to niri-service
sudo systemctl --user add-wants niri.service waybar.service
sudo systemctl --user add-wants niri.service mako.service
sudo systemctl --user add-wants niri.service swaybg.service
sudo systemctl --user add-wants niri.service swayidle.service
sudo systemctl --user add-wants niri.service swayosd.service

# Reload user daemons
sudo systemctl --user daemon-reload
