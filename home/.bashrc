# Interactive check
[[ $- != *i* ]] && return

# Source shared config
source ~/.bashrc.aliases
source ~/.bashrc.functions

# History
HISTSIZE=10000
HISTFILESIZE=10000
HISTCONTROL=ignoreboth:erasedups
shopt -s histappend

# Navigation
shopt -s autocd

# Starship prompt
eval "$(starship init bash)"

# Share history between running shells. Starship replaces PROMPT_COMMAND, so
# append after its init.
PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND; }history -a; history -n"

# fzf
eval "$(fzf --bash)"

# Completion
# bash-completion is optional. git-completion.bash is sourced directly so that
# __git_complete is available for the aliases below.
[[ -r /usr/share/bash-completion/bash_completion ]] &&
  source /usr/share/bash-completion/bash_completion
source /usr/share/git/completion/git-completion.bash

__git_complete gs _git_status
__git_complete gl _git_log
__git_complete gp _git_push
__git_complete gd _git_diff
__git_complete gc _git_commit

# Complete `gd` with changed files only. Options and revision ranges still go
# to git's own completion. Must follow `__git_complete gd`, which defines
# __git_wrap_git_diff.
_gd_changed_files() {
  local cur=${COMP_WORDS[COMP_CWORD]} flag=
  if [[ $cur == -* || $cur == *..* ]]; then
    __git_wrap_git_diff
    return
  fi
  [[ " ${COMP_WORDS[*]} " == *" --cached "* || " ${COMP_WORDS[*]} " == *" --staged "* ]] && flag=--cached
  local IFS=$'\n'
  mapfile -t COMPREPLY < <(compgen -W "$(git diff $flag --name-only --relative 2>/dev/null)" -- "$cur")
}
complete -o bashdefault -o default -F _gd_changed_files gd

bind 'set completion-ignore-case on'
bind 'set show-all-if-ambiguous on'
bind 'set colored-stats on'

# Keybinds
# History search with arrows
bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'

# tmux-sessionizer
bind '"\C-f": "tmux-sessionizer\n"'
