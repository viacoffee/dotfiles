#!/bin/bash

# Helper functions for installation
# Provides logging, output formatting, and error handling

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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
    >> "$COFFEE_INSTALL_LOG_FILE"
}

log() { _log "" "" "$@"; }
info() { _log "INFO" "$BLUE" "$@"; }
important() { _log "==>" "\033[1;34m" "$@"; }
success() { _log "✓" "$GREEN" "$@"; }
warn() { _log "WARNING" "$YELLOW" "$@"; }
error() { _log "ERROR" "$RED" "$@"; exit 1; }

# Logging function - logs command output to install log and displays to stdout
# Usage: run_logged "description" "command"
run_logged() {
  local description="$1"
  local command="$2"
  local exit_code

  # Display what we're doing
  log "$description"

  # Execute command, logging to file and capturing output
  if eval "$command" 2>&1 | tee -a "$COFFEE_INSTALL_LOG_FILE"; then
    log "$description completed"
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

# Install package if not already installed
# Usage: install_package "sddm" "plymouth"
install_package() {
  local packages=("$@")
  local to_install=()
 
  for pkg in "${packages[@]}"; do
    if ! package_installed "$pkg"; then
      to_install+=("$pkg")
    fi
  done
 
  if [ ${#to_install[@]} -gt 0 ]; then
    log "Installing missing packages: ${to_install[*]}"
    sudo pacman -S --noconfirm --needed "${to_install[@]}" || error "Failed to install packages"
    success "Packages installed successfully"
  else
    success "All required packages already installed"
  fi
}

# Print section header
# Usage: section "Display Manager Configuration"
section() {
  local title="$1"
  echo ""
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BLUE}${NC} $title"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
}

# Print summary
# Usage: summary "Component" "Status"
summary() {
  local component="$1"
  local status="$2"
  if [ "$status" = "✓" ]; then
    echo -e "${GREEN}$component: $status${NC}"
  else
    echo -e "${RED}$component: $status${NC}"
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

  log "Checking which packages need to be installed..."

  for pkg in "${packages[@]}"; do
    if ! package_installed "$pkg"; then
      missing+=("$pkg")
      warn "Missing: $pkg"
    else
      success "Installed: $pkg"
    fi
  done

  if (( ${#missing[@]} > 0 )); then
    log "Installing missing packages..."

    run_logged "Installing missing packages: ${missing[*]}" \
      "sudo pacman -S --noconfirm --needed ${missing[*]}"

    success "Package installation completed"
  else
    success "All required packages are already installed"
  fi

  # Verify all packages
  log "Verifying all packages again..."
  for pkg in "${packages[@]}"; do
    if package_installed "$pkg"; then
      success "Verified: $pkg"
    else
      error "Failed to verify package: $pkg"
    fi
  done
}
