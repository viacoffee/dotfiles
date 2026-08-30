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
mkdir -p "$HOME/.cache/zsh"

# Schedule first-login setup only until it has completed once. The service
# remains enabled afterward, with its marker condition preventing reruns.
if ! systemctl --user is-enabled --quiet dot-first-login.service; then
  touch "$HOME/.first-login"
fi

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
  notes
  projects
  work
)
for dir in "${DEFAULT_DIRS[@]}"; do
  mkdir -p "$HOME/$dir"
done

# Refresh font cache
fc-cache -f

verify_user_ownership \
  "$HOME/.cache/zsh" \
  "$HOME/.first-login" \
  "$HOME/notes" \
  "$HOME/projects" \
  "$HOME/work"

log "Updating tldr"
tldr --update || true

# Set shell
log "Changing default shell..."
sudo usermod -s /bin/zsh "$DOTFILES_DEFAULT_USER"
success "Post-install user setup complete"
