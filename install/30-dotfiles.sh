#!/bin/bash

return_pwd=$(pwd)
log "Current directory: $return_pwd"
run_logged "cd to $COFFEE_INSTALL" \
  "cd $COFFEE_INSTALL"

if [[ $EUID -eq 0 && -n $SUDO_USER ]]; then
  USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
  USER_HOME="$HOME"
fi

log "Remove existing bashrc"
[ -f "$USER_HOME/.bashrc" ] && rm -f "$USER_HOME/.bashrc"

run_logged "stowing home" \
  "stow home"

log "Remove niri config if it exists for some reason"
[ -f "$USER_HOME/.config/niri/config.kdl" ] && rm -f "$USER_HOME/.config/niri/config.kdl"

run_logged "stowing config" \
  "stow --no-folding -t $USER_HOME/.config config"
run_logged "stowing local" \
  "stow --no-folding -t $USER_HOME/.local local"

run_logged "cd back to: $return_pwd" \
  "cd $return_pwd"

success "Dotfiles stowed"
