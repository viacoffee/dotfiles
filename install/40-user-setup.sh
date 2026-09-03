#!/bin/bash

# Enable graphical session services
enable_user_services() {
  for svc in "$@"; do
    run_logged "enabling $svc" \
      systemctl --user enable "$svc"
  done
}

# Create zsh cache
step "Creating the Zsh cache"
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

step "Configuring GTK appearance"
gsettings set org.gnome.desktop.interface color-scheme prefer-dark
gsettings set org.gnome.desktop.interface gtk-theme Adwaita-dark

step "Creating default home directories"
DEFAULT_DIRS=(
  notes
  projects
  work
)
for dir in "${DEFAULT_DIRS[@]}"; do
  mkdir -p "$HOME/$dir"
done

step "Installing application menu overrides"
APPLICATION_OVERRIDES_DIR="$HOME/.local/share/applications"
mkdir -p "$APPLICATION_OVERRIDES_DIR"
for desktop_override in "$DOTFILES_INSTALL_DEFAULTS_PATH/applications/"*.desktop; do
  install -m 0644 -- "$desktop_override" \
    "$APPLICATION_OVERRIDES_DIR/${desktop_override##*/}"
done

# Install the repository default wallpaper without stowing it. Keep an
# existing local override.
DEFAULT_BACKGROUND="$DOTFILES_INSTALL_DEFAULTS_PATH/background.jpg"
if [[ ! -e $HOME/background.jpg && ! -L $HOME/background.jpg ]]; then
  cp -- "$DEFAULT_BACKGROUND" "$HOME/background.jpg"
  log "Installed default wallpaper"
fi

verify_user_ownership \
  "$HOME/.cache/zsh" \
  "$HOME/.first-login" \
  "$APPLICATION_OVERRIDES_DIR" \
  "$HOME/notes" \
  "$HOME/projects" \
  "$HOME/work"

# Set shell
step "Changing the default shell"
sudo usermod -s /bin/zsh "$DOTFILES_DEFAULT_USER"
success "Post-install user setup complete"
