#!/bin/bash

if [[ $HOME != "$DOTFILES_USER_HOME" ]]; then
  error "Stow target does not match the home directory validated by preflight"
  return 1
fi

if [[ "$(pwd)" != "$DOTFILES_PATH" ]]; then
  error "Working directory must be $DOTFILES_PATH"
  return 1
fi
log "Working directory: $(pwd)"

log "Remove existing bashrc"
[[ -f "$HOME/.bashrc" ]] && rm -f "$HOME/.bashrc"

log "stowing home"
stow -t "$HOME" home

log "Remove niri config if it exists"
[[ -f "$HOME/.config/niri/config.kdl" ]] && rm -f "$HOME/.config/niri/config.kdl"

mkdir -p "$HOME/.config"
log "stowing config"
stow --no-folding -t "$HOME/.config" config

mkdir -p "$HOME/.local"
log "stowing local"
stow --no-folding -t "$HOME/.local" local

verify_user_ownership "$HOME/.config" "$HOME/.local" "$HOME/.bashrc" "$HOME/.profile" "$HOME/.zshrc"
success "Dotfiles stowed"
