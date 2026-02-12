#!/bin/bash

echo "Setting up systemd --user"

# Add daemons to niri-service
systemctl_want_enable() {
  if [ "$#" -lt 1 ]; then
    echo "Usage: autostart_user_service SERVICE [SERVICE...]"
    return 1
  fi

  for svc in "$@"; do
    echo "Enabling $svc"

    # Add to default.target wants
    systemctl --user add-wants default.target niri.service "$svc"
  done
}

systemctl_want_enable \
  waybar.service \
  mako.service \
  swaybg.service \
  swayidle.service \
  swayosd.service
