# Stats
alias top="btop"
alias htop="btop"
alias ping="prettyping --nolegend"

# Vim
alias vi="nvim"
alias vim="nvim"

# Directory listings
alias l="lsd -l"
alias la="lsd -a"
alias ll="lsd -la"
alias lt="lsd --tree"

# Make a directory and then cd to it
function mkcd() {
  mkdir -p $1 && cd $1
}
