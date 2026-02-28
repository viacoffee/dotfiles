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
export COFFEE_INSTALL_LOG_FILE="${COFFEE_INSTALL_LOG_FILE:-~/.local/state/coffee/install.log}"

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
  if [[ ! -f "$script" ]]; then
    error "$1 not found"
    exit 1
  fi
  source "$script"
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

section "Preflight checks"
run_phase "00-preflight.sh"
echo ""
success "Preflight checks completed"

# System phase - verify and install required base packages
section "System management"
run_phase "10-system.sh"
run_phase "11-user.sh"

# Log vars after user phase adds COFFEE_DEFAULT_USER
log <<EOF
Vars log:
    COFFEE_PATH=$COFFEE_PATH
    COFFEE_INSTALL=$COFFEE_INSTALL 
    COFFEE_INSTALL_LOG_FILE=$COFFEE_INSTALL_LOG_FILE
    COFFEE_INSTALL_DEFAULTS_PATH=$COFFEE_INSTALL_DEFAULTS_PATH
  + COFFEE_DEFAULT_USER=${COFFEE_DEFAULT_USER:-}
EOF

run_phase "12-nvidia.sh"
run_phase "13-greetd.sh"
run_phase "14-bootloader.sh"
echo ""
success "System management phase complete"

# Dotfiles phase - stowing dotfiles
section "Dotfiles"
run_phase "20-dotfiles.sh"
echo ""
success "Dotfiles phase complete"

# Systemd phase - starting systemd services
section "Systemd"
run_phase "30-systemd.sh"

# Post-installation
section "Post-installation"
run_phase "90-post.sh"
echo ""
run_phase "91-mimes.sh"
run_phase "92-firewall.sh"
echo ""
success "Post-installation phase complete"

important "Installation completed at: $(date '+%Y-%m-%d %H:%M:%S')"

section "Overview"
cat <<EOF
  ✓ Bootloader (Limine) verified
  ✓ Boot splash (Plymouth) configured
  ✓ Snapshot management (Snapper) verified
  ✓ Display manager (greetd) configured with autologin
  ✓ Niri session configured
  ✓ Dotfiles stowed

Next Steps:
  1. Reboot

For more details, see:
  - Logs: $COFFEE_INSTALL_LOG_FILE
EOF
