#!/bin/bash

# TODO-david login is probably broken without the greeter user
# Setup greetd/tuigreet
# if ! id greeter &>/dev/null; then
#   sudo useradd -r -s /usr/bin/nologin greeter
# fi
#
# sudo tee /etc/greetd/config.toml > /dev/null << 'EOF'
# [terminal]
# vt = 1
#
# [default_session]
# command = "tuigreet --asterisks --window-padding 2 --container-padding 1 --width 50 --cmd niri-session"
# user = "greeter"
# EOF

# greetd configuration for autologin
log "Configuring autologin for greetd"

greetd_path="/etc/greetd"

log "Creating greetd configuration directory..."
run_logged "Create $greetd_path" \
  "sudo mkdir -p $greetd_path"

# Create config if it doesn't exist
if [ ! -f $greetd_path/config.toml ]; then
  sudo touch "$greetd_path/config.toml"
fi

run_logged "Setting greetd config options" \
  "cat <<'EOF' | sudo tee $greetd_path/config.toml
[terminal]
vt = 1

[default_session]
command = \"niri-session\"
user = \"$COFFEE_DEFAULT_USER\"

[dbus]
enable = true
EOF"

info "$greetd_path/config.toml contents:"
info cat "$greetd_path/config.toml"

log "Enabling greetd systemd service..."
run_logged "Enable greetd service" \
  "sudo systemctl enable greetd"

success "greetd configuration complete"
log "Default autologin user: $COFFEE_DEFAULT_USER"
