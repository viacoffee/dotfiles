# Interactive check
[[ $- != *i* ]] && return

# Source shared config
source ~/.zshrc.aliases
source ~/.zshrc.functions

# Starship prompt
eval "$(starship init zsh)"

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
HISTSIZE=10000
SAVEHIST=10000

setopt appendhistory
setopt share_history
setopt hist_ignore_dups
setopt hist_reduce_blanks

# Navigation
setopt autocd

# Keybinds
bindkey -e

# History search with arrows
bindkey '\e[A' history-search-backward
bindkey '\e[B' history-search-forward
