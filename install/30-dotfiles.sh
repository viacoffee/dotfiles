#!/bin/bash

return_pwd=pwd
log "Current directory: $return_pwd"
run_logged "cd to $COFFEE_INSTALL" \
  "cd $COFFEE_INSTALL"

run_logged "stowing home" \
  "stow home"
run_logged "stowing config" \
  "stow --no-folding -t ~/.config config"
run_logged "stowing local" \
  "stow --no-folding -t ~/.local local"

run_logged "cd back to: $return_pwd" \
  "cd $return_pwd"

success "Dotfiles stowed"
