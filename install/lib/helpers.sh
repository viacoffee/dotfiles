#!/usr/bin/env bash

# Exit on error, undefined variables, and pipe failures
set -euo pipefail

info() { printf "\033[1;34m==> %s\033[0m\n" "$*"; }
warn() { printf "\033[1;33m!!! %s\033[0m\n" "$*"; }
error() { printf "\033[1;31m=== %s\033[0m\n" "$*"; }

install_packages_from_file() {
  local package_file="$1"
  
  # Validate input file exists and is readable
  if [[ ! -f "$package_file" ]]; then
    error "Package file not found: $package_file"
    return 1
  fi
  
  if [[ ! -r "$package_file" ]]; then
    error "Package file not readable: $package_file"
    return 1
  fi
  
  # Read packages from file, filtering comments and empty lines
  local -a packages
  mapfile -t packages < <(grep -v '^#' "$package_file" | grep -v '^$' || true)
  
  if [[ ${#packages[@]} -eq 0 ]]; then
    warn "No packages found in $package_file"
    return 0
  fi
  
  info "Installing packages from $(basename "$package_file")..."
  
  # Install packages with error handling
  if ! sudo pacman -S --needed --noconfirm "${packages[@]}"; then
    error "Failed to install some packages from $package_file"
    return 1
  fi
  
  info "Package installation completed successfully"
}

# Validate and source a script file safely
source_script() {
  local script_path="$1"
  
  # Validate file exists
  if [[ ! -f "$script_path" ]]; then
    error "Script not found: $script_path"
    return 1
  fi
  
  # Validate file is readable
  if [[ ! -r "$script_path" ]]; then
    error "Script not readable: $script_path"
    return 1
  fi
  
  # Validate file is a regular file (not a directory or special file)
  if [[ ! -f "$script_path" ]]; then
    error "Not a regular file: $script_path"
    return 1
  fi
  
  # Source the script with error handling
  if ! source "$script_path"; then
    error "Failed to source: $script_path"
    return 1
  fi
}

# Check if a command exists in PATH
command_exists() {
  local cmd="$1"
  if ! command -v "$cmd" &>/dev/null; then
    error "Required command not found: $cmd"
    return 1
  fi
}
