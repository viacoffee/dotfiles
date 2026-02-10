#!/bin/bash

# Add daemons to niri-service
systemctl --user add-wants default.target niri.service waybar.service
systemctl --user add-wants default.target niri.service mako.service
systemctl --user add-wants default.target niri.service swaybg.service
systemctl --user add-wants default.target niri.service swayidle.service
systemctl --user add-wants default.target niri.service swayosd.service

# Reload user daemons
systemctl --user daemon-reload
