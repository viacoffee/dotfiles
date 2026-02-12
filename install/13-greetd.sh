#!/bin/bash

# greetd configuration for autologin with fallback to bare TTY
log "Configuring greetd for direct autologin"

log "Creating greetd configuration directory..."
run_logged "Create /etc/greetd" \
  "sudo mkdir -p /etc/greetd"

# Configure greetd with initial session (autologin) and fallback to bare shell
if [ ! -f /etc/greetd/config.toml ]; then
  log "Creating greetd configuration..."
  run_logged "Create greetd config" \
    "cat <<'EOF' | sudo tee /etc/greetd/config.toml
[terminal]
vt = \"next\"

[general]
source_profile = true

[initial_session]
command = \"niri-session\"
user = \"$COFFEE_DEFAULT_USER\"

[default_session]
command = \"/bin/sh\"
user = \"$COFFEE_DEFAULT_USER\"
EOF"
  success "Greetd configuration created for user: $COFFEE_DEFAULT_USER"
else
  log "Greetd configuration already exists at /etc/greetd/config.toml"
  success "Skipping greetd configuration (already configured)"
fi

# Enable greetd service
run_logged "Enable greetd service" \
  "sudo systemctl enable greetd.service"

success "greetd configuration complete"
info "Auto-login user: $COFFEE_DEFAULT_USER"
info "Fallback: bare TTY shell on session exit"
