# Interactive check
[[ $- != *i* ]] && return

# Starship prompt
eval "$(starship init zsh)"

# Stats
alias top="btop"
alias htop="btop"
alias ping="prettyping --nolegend"

# Vim
alias vi="nvim"
alias vim="nvim"

# Directory listings
alias l="lsd -a1"
alias la="lsd -la"
alias lr="lsd -R"
alias lra="lsd -RA"
alias lt="lsd --tree"

# Add ~/.local/bin to PATH
if [ -d "$HOME/.local/bin" ]; then
  export PATH="$HOME/.local/bin:$PATH"
fi

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
