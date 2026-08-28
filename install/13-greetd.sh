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
command = "uwsm start niri-session"
user = "$DOTFILES_DEFAULT_USER"

[default_session]
command = "/bin/sh"
user = "$DOTFILES_DEFAULT_USER"
EOF

# Prevent niri.service from auto-starting via default.target (uwsm manages it)
run_logged "Disable niri.service user unit" sudo -u "$DOTFILES_DEFAULT_USER" \
  systemctl --user disable niri.service || true

success "greetd configuration complete"
log "Auto-login user: $DOTFILES_DEFAULT_USER"
