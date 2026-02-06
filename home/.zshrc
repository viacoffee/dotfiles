# Interactive check
[[ $- != *i* ]] && return

# Starship
eval "$(starship init zsh)"

# Load bashrc
[ -r "$HOME/.bashrc" ] && . "$HOME/.bashrc"

# History
setopt share_history

# Navigation
setopt autocd

# Keybinds
bindkey -e
