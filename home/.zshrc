# Interactive check
[[ $- != *i* ]] && return

# Source shared config
source ~/.zshrc.aliases
source ~/.zshrc.functions

# Starship prompt
eval "$(starship init zsh)"

# Completion
autoload -Uz compinit
zmodload zsh/complist

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

zcompdump="$HOME/.cache/zsh/zcompdump"
zcompstamp="$HOME/.cache/zsh/zcompdump.last-check"

# Refresh completion definitions twice daily; use the fast cached path for
# every other shell.
if [[ ! -s $zcompdump ||
      ! -e $zcompstamp ||
      -n ${~zcompstamp}(N.mh+12) ]]; then
  compinit -d "$zcompdump" && : >| "$zcompstamp"
else
  compinit -C -d "$zcompdump"
fi

unset zcompdump zcompstamp

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

# tmux-sessionizer
bindkey -s '^F' 'tmux-sessionizer\n'
