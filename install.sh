#!/bin/bash

set -eEuo pipefail

if [[ -z "${COFFEE_PATH:-}" ]]; then
  export COFFEE_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

if [[ "$(pwd)" != "$COFFEE_PATH" ]]; then
  echo "Error: install.sh must be run from the dotfiles root ($COFFEE_PATH)"
  exit 1
fi

if [[ -z "${COFFEE_INSTALL:-}" ]]; then
  export COFFEE_INSTALL="$COFFEE_PATH/install"
fi

export COFFEE_INSTALL_DEFAULTS_PATH="$COFFEE_INSTALL/default"
export COFFEE_INSTALL_LOG_FILE="${COFFEE_INSTALL_LOG_FILE:-$HOME/.local/state/coffee/install.log}"

# Ensure log file exists
mkdir -p "$(dirname "$COFFEE_INSTALL_LOG_FILE")" 2>/dev/null || true
touch "$COFFEE_INSTALL_LOG_FILE"

# Source helper functions FIRST (before any function calls)
if [[ ! -f "$COFFEE_INSTALL/lib/helpers.sh" ]]; then
  echo "Error: Helper functions not found at $COFFEE_INSTALL/lib/helpers.sh"
  exit 1
fi
source "$COFFEE_INSTALL/lib/helpers.sh"

# Restore mkinitcpio hooks if install fails between preflight and bootloader phases
_restore_mkinitcpio_hooks() {
  local hook_dir="/usr/share/libalpm/hooks"
  for hook in 90-mkinitcpio-install 60-mkinitcpio-remove; do
    if [[ -f "$hook_dir/${hook}.hook.disabled" ]]; then
      sudo mv "$hook_dir/${hook}.hook.disabled" "$hook_dir/${hook}.hook" 2>/dev/null || true
    fi
  done
}
trap _restore_mkinitcpio_hooks EXIT

# Source a numbered install phase script or exit
run_phase() {
  local script="$COFFEE_INSTALL/$1"
  local title="${2:-$1}"
  if [[ ! -f "$script" ]]; then
    error "Phase script not found: $script"
    exit 1
  fi
  section "$title"
  info "Running $1"
  source "$script"
  success "$title complete"
}

section "https://github.com/viacoffee/dotfiles"
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

info "Installing system from: $COFFEE_PATH"
important "Logfile: $COFFEE_INSTALL_LOG_FILE"
log <<EOF
Vars log:
  + COFFEE_PATH=$COFFEE_PATH
  + COFFEE_INSTALL=$COFFEE_INSTALL 
  + COFFEE_INSTALL_LOG_FILE=$COFFEE_INSTALL_LOG_FILE
  + COFFEE_INSTALL_DEFAULTS_PATH=$COFFEE_INSTALL_DEFAULTS_PATH
EOF
log "Installation started at: $(date '+%Y-%m-%d %H:%M:%S')"

echo ""
log "Starting installation phases..."

run_phase "00-preflight.sh" "Preflight checks"

# System phase - install required packages
section "System management"
run_phase "10-system.sh" "Packages and repositories"
run_phase "11-user.sh" "User account"

# Log vars after user phase adds COFFEE_DEFAULT_USER
log <<EOF
Vars log:
    COFFEE_PATH=$COFFEE_PATH
    COFFEE_INSTALL=$COFFEE_INSTALL 
    COFFEE_INSTALL_LOG_FILE=$COFFEE_INSTALL_LOG_FILE
    COFFEE_INSTALL_DEFAULTS_PATH=$COFFEE_INSTALL_DEFAULTS_PATH
  + COFFEE_DEFAULT_USER=${COFFEE_DEFAULT_USER:-}
EOF

run_phase "12-nvidia.sh" "NVIDIA drivers"
run_phase "13-greetd.sh" "Display manager"
run_phase "14-bootloader.sh" "Bootloader and boot process"
success "System management complete"

# Dotfiles phase - stowing dotfiles
run_phase "20-dotfiles.sh" "Dotfiles"

# Systemd phase - starting systemd services
run_phase "30-systemd.sh" "System services"

run_phase "90-post.sh" "User services and directories"
run_phase "91-mimes.sh" "Desktop defaults"
run_phase "92-firewall.sh" "Firewall"

success "Installation completed"
info "Reboot to start the configured desktop session."
info "Installation log: $COFFEE_INSTALL_LOG_FILE"
