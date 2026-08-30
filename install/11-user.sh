#!/bin/bash

# User Account Verification and Configuration
# Uses the normal-user identity established by preflight.

log "Verifying user account for autologin..."

if [[ -z ${DOTFILES_DEFAULT_USER:-} || -z ${DOTFILES_DEFAULT_UID:-} || -z ${DOTFILES_USER_HOME:-} ]]; then
  error "Preflight did not establish the installer user"
  return 1
fi
if [[ $(id -un) != "$DOTFILES_DEFAULT_USER" || $(id -u) != "$DOTFILES_DEFAULT_UID" ]]; then
  error "Installer user changed after preflight"
  return 1
fi
if [[ $HOME != "$DOTFILES_USER_HOME" ]]; then
  error "HOME changed after preflight"
  return 1
fi

success "User verification completed"
log "Default login user: $DOTFILES_DEFAULT_USER"
