#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$DOTFILES_DIR"

stow home
# TODO-david might not work on initial
stow --no-folding -t ~/.config config
stow -t ~/.local local
