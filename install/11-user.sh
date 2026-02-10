#!/bin/bash

# User Account Verification and Configuration
# Verifies and configures the non-root user running the script for autologin

log "Verifying user account for autologin..."

# Get the user running the script (the one with sudo privileges)
# When run with sudo, we need to get the original user, not root
if [ -n "$SUDO_USER" ]; then
  # Script was run with sudo, use the original user
  LOGIN_USER="$SUDO_USER"
  success "Detected user running with sudo: $LOGIN_USER"
elif [ "$EUID" -ne 0 ]; then
  # Script not run with sudo, use current user
  LOGIN_USER="$(whoami)"
  success "Detected current user: $LOGIN_USER"
else
  # Script is running as root without sudo (not recommended)
  error "Script must be run as a non-root user or with sudo from a non-root user"
  exit 1
fi

# Validate that LOGIN_USER is not root
if [ "$LOGIN_USER" = "root" ]; then
  error "Autologin cannot be configured for root user. Please run the installer as a non-root user."
  exit 1
fi

# Ensure user home directory exists
if [ ! -d "/home/$LOGIN_USER" ]; then
  log "Home directory does not exist for user: $LOGIN_USER"
  log "Creating home directory..."
  run_logged "Create home directory" \
    "sudo mkdir -p /home/$LOGIN_USER"
fi

# Set proper permissions on home directory
log "Setting home directory ownership..."
run_logged "Set home directory owner" \
  "sudo chown -R $LOGIN_USER:$LOGIN_USER /home/$LOGIN_USER"

run_logged "Set home directory permissions" \
  "sudo chmod 755 /home/$LOGIN_USER"

# Export the username for use in subsequent scripts
export COFFEE_DEFAULT_USER="$LOGIN_USER"

success "User verification completed"
log "Default login user: $LOGIN_USER"
