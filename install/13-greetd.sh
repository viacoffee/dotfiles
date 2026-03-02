#!/bin/bash

# greetd configuration for autologin with fallback to bare TTY
log "Configuring greetd for direct autologin"

log "Creating greetd configuration directory..."
run_logged "Create /etc/greetd" sudo mkdir -p /etc/greetd

# Configure greetd with initial session (autologin) and fallback to bare shell
log "Create greetd config"
sudo tee /etc/greetd/config.toml > /dev/null <<EOF
[terminal]
vt = "next"

[general]
source_profile = true

[initial_session]
command = "uwsm start niri"
user = "$COFFEE_DEFAULT_USER"

[default_session]
command = "/bin/sh"
user = "$COFFEE_DEFAULT_USER"
EOF

success "greetd configuration complete"
log "Auto-login user: $COFFEE_DEFAULT_USER"
