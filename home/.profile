# Set default editor
export EDITOR="nvim"
export VISUAL="$EDITOR"

# Add ~/.local/bin to PATH
if [ -d "$HOME/.local/bin" ]; then
  export PATH="$HOME/.local/bin:$PATH"
fi

# Wayland session
if [ -z "$WAYLAND_DISPLAY" ] && [ -n "$DISPLAY" ]; then
  export WAYLAND_DISPLAY="wayland-0"
fi

# TODO-david
# merge the two
if [ -z "$WAYLAND_DISPLAY" ] && [ "$XDG_VTNR" -eq 1 ]; then
  exec niri-session
fi

# Load bashrc for login shells
[ -r "$HOME/.bashrc" ] && . "$HOME/.bashrc"
