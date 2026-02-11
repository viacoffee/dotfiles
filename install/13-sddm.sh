#!/bin/bash

# greetd configuration for autologin
log "Configuring autologin for sddm"

log "Creating SDDM configuration directory..."
run_logged "Create /etc/sddm.conf.d" \
  "sudo mkdir -p /etc/sddm.conf.d"

# Configure autologin
if [ ! -f /etc/sddm.conf.d/autologin.conf ]; then
  log "Creating autologin configuration..."
  run_logged "Create autologin configuration" \
    "cat <<'EOF' | sudo tee /etc/sddm.conf.d/autologin.conf
[Autologin]
User=$COFFEE_DEFAULT_USER
Session=niri

[General]
Session=niri
EOF"
  success "Autologin configuration created for user: $COFFEE_DEFAULT_USER"
else
  log "Autologin configuration already exists at /etc/sddm.conf.d/autologin.conf"
  success "Skipping autologin configuration (already configured)"
fi

success "sddm configuration complete"
log "Default autologin user: $COFFEE_DEFAULT_USER"
