#!/bin/bash

# Enable graphical session services
enable_user_services() {
  for svc in "$@"; do
    run_logged "enabling $svc" \
      systemctl --user enable "$svc"
  done
}

# Create zsh cache
log "Creating zsh cache directory..."
mkdir -p ~/.cache/zsh

# Enable session services
enable_user_services \
  waybar \
  mako \
  swaybg \
  swayidle \
  swayosd \
  dot-first-login

log "Creating default home directories"
DEFAULT_DIRS=(
  Notes
  Projects
  Work
)
for dir in "${DEFAULT_DIRS[@]}"; do
  mkdir -p "$HOME/$dir"
done

# Refresh font cache
fc-cache -f

# Enable dnd mode for mako (deferred to first login)
touch "$HOME/.first-login"

log "Updating tldr"
tldr --update || true

# Set shell
log "Changing default shell..."
sudo usermod -s /bin/zsh "$DOTFILES_DEFAULT_USER"
success "Post-install user setup complete"
