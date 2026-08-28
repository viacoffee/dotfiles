#!/bin/bash

# Helper functions for installation
# Provides logging, output formatting, and error handling

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

_read_message() {
  if [[ -t 0 ]]; then
    printf '%s' "$*"
  else
    cat
  fi
}

_log() {
  local level="$1"
  local color="$2"
  shift 2

  local message
  message="$(_read_message "$@")"

  if [[ -n $level ]]; then
    if [[ -n $color ]]; then
      printf '%b\n' "${color}${level}${NC} $message"
    else
      printf '%s %s\n' "$level" "$message"
    fi
  else
    printf '%s\n' "$message"
  fi

  printf '[%s] %s\n' "$(date '+%F %T')" "$message" \
    >> "$DOTFILES_INSTALL_LOG_FILE"
}

log() { _log "" "" "$@"; }
info() { _log "INFO" "$BLUE" "$@"; }
important() { _log "==>" "\033[1;34m" "$@"; }
success() { _log "✓" "$GREEN" "$@"; }
warn() { _log "WARNING" "$YELLOW" "$@"; }
error() { _log "ERROR" "$RED" "$@"; }

# Logging function - logs command output to install log and displays to stdout
# Usage: run_logged "description" command arg1 arg2 ...
run_logged() {
  local description="$1"; shift
  local exit_code

  log "$description"

  if "$@" 2>&1 | tee -a "$DOTFILES_INSTALL_LOG_FILE"; then
    success "$description completed"
    return 0
  else
    exit_code=$?
    error "$description failed with exit code $exit_code"
    return "$exit_code"
  fi
}

# Check if command exists
# Usage: command_exists "pacman"
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Check if package is installed (pacman)
# Usage: package_installed "sddm"
package_installed() {
  pacman -Q "$1" >/dev/null 2>&1
}

# Print section header
# Usage: section "Display Manager Configuration"
section() {
  local title="$1"
  echo ""
  printf '%b\n' "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  printf '%b\n' "${BLUE}${NC} $title"
  printf '%b\n' "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  log "Starting: $title"
  echo ""
}

# Print summary
# Usage: summary "Component" "Status"
summary() {
  local component="$1"
  local status="$2"
  if [[ "$status" = "✓" ]]; then
    printf '%b\n' "${GREEN}$component: $status${NC}"
  else
    printf '%b\n' "${RED}$component: $status${NC}"
  fi
}

# Install missing packages
# Usage:
# system_packages=(
#   git
#   neovim
#   ripgrep
#   fd
# )
#
# install_missing_packages "${system_packages[@]}"
#
# OR inline:
# install_missing_packages git neovim ripgrep fd
install_missing_packages() {
  local packages=("$@")
  local missing=()

  info "Checking ${#packages[@]} required packages..."

  for pkg in "${packages[@]}"; do
    if ! package_installed "$pkg"; then
      missing+=("$pkg")
    fi
  done

  if (( ${#missing[@]} > 0 )); then
    info "Installing ${#missing[@]} missing package(s): ${missing[*]}"
    log "Installing missing packages..."

    run_logged "Installing missing packages: ${missing[*]}" \
      sudo pacman -S --noconfirm --needed "${missing[@]}"

    info "Verifying installed packages..."
    local verify_failed=0
    for pkg in "${packages[@]}"; do
      if ! package_installed "$pkg"; then
        error "Failed to verify package: $pkg"
        verify_failed=1
      fi
    done
    if (( verify_failed )); then
      return 1
    fi
  fi

  if (( ${#missing[@]} == 0 )); then
    info "All required packages were already installed."
  fi
  success "Required packages are installed and verified"
}
