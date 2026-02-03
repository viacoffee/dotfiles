#!/usr/bin/env bash
set -euo pipefail

info() { printf "\033[1;34m==> %s\033[0m\n" "$*"; }

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$DOTFILES_DIR/install"

info "Bootstrapping system from $DOTFILES_DIR"

for phase in "$INSTALL_DIR"/*.sh; do
  info "Running $(basename "$phase")"
  bash "$phase"
done

info "Bootstrap complete"
