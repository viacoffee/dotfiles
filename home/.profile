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
