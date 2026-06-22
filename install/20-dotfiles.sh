#!/bin/bash

if [[ $EUID -eq 0 && -n $SUDO_USER ]]; then
  USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
  USER_HOME="$HOME"
fi

if [[ "$(pwd)" != "$COFFEE_PATH" ]]; then
  error "Working directory must be $COFFEE_PATH"
  return 1
fi
log "Working directory: $(pwd)"

log "Remove existing bashrc"
[[ -f "$USER_HOME/.bashrc" ]] && rm -f "$USER_HOME/.bashrc"

log "stowing home"
stow home

log "Remove niri config if it exists"
[[ -f "$USER_HOME/.config/niri/config.kdl" ]] && rm -f "$USER_HOME/.config/niri/config.kdl"

mkdir -p "$USER_HOME/.config"
log "stowing config"
stow --no-folding -t "$USER_HOME/.config" config

mkdir -p "$USER_HOME/.local"
log "stowing local"
stow --no-folding -t "$USER_HOME/.local" local

log "Generating themed configs"
"$USER_HOME/.local/bin/coffee-theme-refresh"

success "Dotfiles stowed"
