# Interactive check
[[ $- != *i* ]] && return

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

# Make a directory and then cd to it
function mkcd() {
  mkdir -p $1 && cd $1
}

# Make a directory and move file to it
function mkmv() {
  mkdir -p $2 && mv $1 $2
}

# Add ~/.local/bin to PATH
if [ -d "$HOME/.local/bin" ]; then
  export PATH="$HOME/.local/bin:$PATH"
fi
