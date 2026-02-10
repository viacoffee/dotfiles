#!/bin/bash

# Dotfiles phase - stowing dotfiles
section "Dotfiles"

current_pwd=pwd
log "Current directory: $current_pwd"
run_logged "cd to $COFFEE_INSTALL" \
  "cd $COFFEE_INSTALL"

run_logged "stowing home" \
  "stow home"
run_logged "stowing config" \
  "stow --no-folding -t ~/.config config"
run_logged "stowing local" \
  "stow --no-folding -t ~/.local local"

run_logged "cd back to: $current_pwd" \
  "cd $current_pwd"

success "Dotfiles stowed"
