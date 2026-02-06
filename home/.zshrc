# Interactive check
[[ $- != *i* ]] && return

# Starship prompt
eval "$(starship init zsh)"

# Load bashrc (if needed for env vars etc.)
[ -r "$HOME/.bashrc" ] && . "$HOME/.bashrc"

# Completion (compinit) — cached
autoload -Uz compinit
zmodload zsh/complist

# Completion behavior
zstyle ':completion:*' menu select
zstyle ':completion:*' rehash true
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# Use cache for speed
compinit -d ~/.cache/zsh/zcompdump

# History
HISTFILE=~/.zsh_history
HISTSIZE=1000
SAVEHIST=1000

setopt appendhistory
# setopt share_history
setopt hist_ignore_dups
setopt hist_reduce_blanks

# Navigation
setopt autocd

# Keybinds
bindkey -e

# History search with arrows
bindkey '\e[A' history-search-backward
bindkey '\e[B' history-search-forward

# Accept autosuggestion with →
bindkey '^[[C' autosuggest-accept

# Autosuggestions
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
