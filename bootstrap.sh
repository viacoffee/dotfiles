#!/bin/bash
set -euo pipefail

# Curl-able bootstrap for viacoffee/dotfiles
# Usage:
#   bash <(curl -sL https://raw.githubusercontent.com/viacoffee/dotfiles/main/bootstrap.sh)
#   bash <(curl -sL https://raw.githubusercontent.com/viacoffee/dotfiles/main/bootstrap.sh) -b back_to_arch

REPO_URL="https://github.com/viacoffee/dotfiles.git"
CLONE_DIR="$HOME/dotfiles"
BRANCH=""

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

info()  { printf "${BLUE}INFO${NC} %s\n" "$*"; }
warn()  { printf "${YELLOW}WARNING${NC} %s\n" "$*"; }
error() { printf "${RED}ERROR${NC} %s\n" "$*" >&2; }

# parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    -b|--branch)
      BRANCH="$2"
      shift 2
      ;;
    -h|--help)
      cat <<EOF
Usage: bootstrap.sh [-b|--branch <branch>]

Options:
  -b, --branch <name>   Branch to clone (default: repo default)
  -h, --help            Show this help message
EOF
      exit 0
      ;;
    *)
      error "Unknown option: $1"
      exit 1
      ;;
  esac
done

# ensure git is available
if ! command -v git &>/dev/null; then
  warn "git is not installed"
  info "Attempting to install git via pacman..."
  sudo pacman -S --noconfirm git
fi

# guard against clobbering an existing clone
if [[ -d "$CLONE_DIR" ]]; then
  error "$CLONE_DIR already exists — remove or rename it first"
  exit 1
fi

# clone
clone_args=(--recurse-submodules)
if [[ -n "$BRANCH" ]]; then
  clone_args+=(-b "$BRANCH")
  info "Cloning branch: $BRANCH"
else
  info "Cloning default branch"
fi

git clone "${clone_args[@]}" "$REPO_URL" "$CLONE_DIR"
echo ""
info "Repository cloned to $CLONE_DIR"

# confirm before install
echo ""
printf "${BOLD}${YELLOW}"
cat <<'EOF'
  This will run install.sh, which configures packages, bootloader,
  firewall, display manager, and other system-level settings.
  This is a DESTRUCTIVE operation intended for a fresh Arch install.
EOF
printf "${NC}"
echo ""

read -rp "Continue with installation? [y/N] " answer
if [[ ! "$answer" =~ ^[Yy]$ ]]; then
  info "Aborted. You can run it later with: bash $CLONE_DIR/install.sh"
  exit 0
fi

exec bash "$CLONE_DIR/install.sh"
