# Set default editor
export EDITOR="nvim"
export VISUAL="$EDITOR"

# Suppress uwsm console output during session start
export UWSM_SILENT_START=1

# Add ~/.local/bin to PATH
if [ -d "$HOME/.local/bin" ]; then
  case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) export PATH="$HOME/.local/bin:$PATH" ;;
  esac
fi

# Mise shims make opt-in language runtimes available in login shells.
if command -v mise >/dev/null 2>&1 && [ -d "$HOME/.local/share/mise/shims" ]; then
  case ":$PATH:" in
    *":$HOME/.local/share/mise/shims:"*) ;;
    *) export PATH="$HOME/.local/share/mise/shims:$PATH" ;;
  esac
fi
