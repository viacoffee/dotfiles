# Login shells read this file instead of ~/.profile, so load both.
[[ -f ~/.profile ]] && . ~/.profile
[[ -f ~/.bashrc ]] && . ~/.bashrc
