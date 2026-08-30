#!/bin/bash
set -euo pipefail

# Curl-able bootstrap for viacoffee/dotfiles
# Usage:
#   sudo pacman -S --needed curl && bash <(curl -fsSL https://raw.githubusercontent.com/viacoffee/dotfiles/master/bootstrap.sh)
#   sudo pacman -S --needed curl && bash <(curl -fsSL https://raw.githubusercontent.com/viacoffee/dotfiles/master/bootstrap.sh) -b back_to_arch

REPO_URL="https://github.com/viacoffee/dotfiles.git"
CLONE_DIR="$HOME/dotfiles"
BRANCH=""

# parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    -b|--branch)
      if [[ -z "${2:-}" ]]; then
        echo "ERROR: -b/--branch requires a branch name" >&2
        echo "Usage: bootstrap.sh [-b|--branch <branch>]" >&2
        exit 1
      fi
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
      echo "ERROR: Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

cat <<'EOF'
      )  (
     (   ) )
      ) ( (
    _______)_
 .-'---------|
( C|/\/\/\/\/|
 '-./\/\/\/\/|
   '_________'
    '-------'

EOF

echo "https://github.com/viacoffee/dotfiles"
echo ""
echo "Bootstrap will clone the dotfiles and start the Arch installation."
echo "Target directory: $CLONE_DIR"
[[ -n "$BRANCH" ]] && echo "Requested branch: $BRANCH"
echo ""

# ensure git is available
if ! command -v git &>/dev/null; then
  echo "[1/3] Git is not installed; installing it with pacman..."
  sudo pacman -S --noconfirm git
else
  echo "[1/3] Git is available."
fi

# guard against clobbering an existing clone
if [[ -d "$CLONE_DIR" ]]; then
  echo "ERROR: $CLONE_DIR already exists — remove or rename it first" >&2
  exit 1
fi

# clone
clone_args=(--recurse-submodules)
if [[ -n "$BRANCH" ]]; then
  clone_args+=(-b "$BRANCH")
  echo "Cloning branch: $BRANCH"
else
  echo "Cloning default branch"
fi

echo "[2/3] Cloning repository..."
git clone "${clone_args[@]}" "$REPO_URL" "$CLONE_DIR"
echo "Repository cloned to $CLONE_DIR"
echo ""

# confirm before install
echo ""
printf '\033[1m\033[1;33m'
cat <<'EOF'
  This will run install.sh, which configures packages, bootloader,
  firewall, display manager, and other system-level settings.
  This is a DESTRUCTIVE operation intended for a fresh Arch install.
EOF
printf '\033[0m'
echo ""

printf 'This will make system-wide changes and may take some time.\n'
answer=""
if [[ -r /dev/tty ]]; then
  read -rp "[3/3] Start the installation now? [y/N] " answer </dev/tty || true
else
  read -rp "[3/3] Start the installation now? [y/N] " answer || true
fi
if [[ ! "$answer" =~ ^[Yy]$ ]]; then
  echo "Aborted. You can run it later with: bash $CLONE_DIR/install.sh"
  exit 0
fi

if ! cd "$CLONE_DIR"; then
  echo "ERROR: Failed to cd into $CLONE_DIR" >&2
  exit 1
fi

echo "Starting installer..."
exec bash install.sh
