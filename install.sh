#!/usr/bin/env bash

cd "$(dirname "$0")" || exit

# category, sub_category, success, and error are defined in helpers
source "includes/helpers.sh"
source "includes/remove_bloat.sh"
source "includes/settings.sh"

###
category "System"
###

sub_category "updating system"
sudo pacman -Syu

sub_category "install packages"
cat <<EOD | xargs sudo pacman -S --noconfirm --needed
  stow
  firefox
  tldr
  lsd
  prettyping
  ttf-space-mono-nerd
  meson
  cmake
  cpio
  ripgrep
EOD

# install term
omarchy-install-terminal alacritty

sub_category "configuring packages"
# TODO-david
#hyprpm update
#hyprpm add https://github.com/zakk4223/hyprWorkspaceLayouts
#hyprpm enable hyprWorkspaceLayouts

sub_category "create symlinks"
# symlinks for vi/vim
sudo ln -sf /usr/bin/nvim /usr/bin/vi
sudo ln -sf /usr/bin/nvim /usr/bin/vim

# set firefox as default browser
sub_category "set browser"
xdg-settings set default-web-browser firefox.desktop

# download tldr entries
sub_category "downloading tldr entries"
tldr -u

###
category "Dotfiles"
###
sub_category "bash"
rmvoid ~/.bashrc
rmvoid ~/.profile
stow --no-folding shell

sub_category "alacritty"
rm -rf ~/.config/alacritty
stow alacritty

sub_category "waybar"
rm -rf ~/.config/waybar 2>/dev/null
stow waybar

sub_category "hyprland"
rmvoid ~/.config/hypr/hypridle.conf
rmvoid ~/.config/hypr/input.conf
rmvoid ~/.config/hypr/bindings.conf
rm -rf ~/.config/hypr/bindings 2>/dev/null
rmvoid ~/.config/hypr/hyprland.conf
rmvoid ~/.config/hypr/looknfeel.conf
rmvoid ~/.config/hypr/autostart.conf
stow --no-folding hypr
hyprctl reload # reload hyprland

sub_category "lsd"
rm -rf ~/.config/lsd 2>/dev/null
stow lsd

sub_category "vim"
rm -rf ~/.config/nvim ~/.local/share/nvim 2>/dev/null
stow nvim

sub_category "starship"
rmvoid ~/.config/starship.toml
stow --no-folding starship

###
category "Development Environment"
###
cat <<EOD | xargs omarchy-install-dev-env
    ruby
    python
    node
EOD

###
# Changes to configs, keybinds, and style
# doing this last since we delete a lot of the default files above
category "Omarchy"
###
sub_category "remove bloat"
remove_all # includes/remove_bloat.sh function

if [[ ! "$(~/.local/share/omarchy/bin/omarchy-theme-list)" =~ "$THEME_NAME" ]]; then
    sub_category "install theme"
    omarchy-theme-install "$THEME_URL"
fi

if [ "$(~/.local/share/omarchy/bin/omarchy-theme-current)" != "$THEME_NAME" ]; then
    sub_category "set theme"
    omarchy-theme-set "$THEME_NAME"
fi

if [ "$(~/.local/share/omarchy/bin/omarchy-font-current)" != "$FONT_NAME" ]; then
    sub_category "set font"
    omarchy-font-set "$FONT_NAME"
fi

gum style --foreground=32 --bold --padding "1 2" "//Dotfiles complete!"
