#!/bin/bash

# Exit immediately if a command exists with a non-zero status
set -eEo pipefail

if [ -z "$COFFEE_PATH" ]; then
  export COFFEE_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

if [ -z "$COFFEE_INSTALL" ]; then
  export COFFEE_INSTALL="$COFFEE_PATH/install"
fi

export COFFEE_INSTALL_DEFAULTS_PATH="$COFFEE_INSTALL/default"
export COFFEE_INSTALL_LOG_FILE="${COFFEE_INSTALL_LOG_FILE:-~/.local/state/coffee/install.log}"

# Ensure log file exists
mkdir -p "$(dirname "$COFFEE_INSTALL_LOG_FILE")" 2>/dev/null || true
touch "$COFFEE_INSTALL_LOG_FILE"

# Source helper functions FIRST (before any function calls)
if [ ! -f "$COFFEE_INSTALL/lib/helpers.sh" ]; then
  echo "Error: Helper functions not found at $COFFEE_INSTALL/lib/helpers.sh"
  exit 1
fi
source "$COFFEE_INSTALL/lib/helpers.sh"

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

info "Bootstrapping system from: $COFFEE_PATH"
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
# Phase 1: Preflight checks
if [ -f "$COFFEE_INSTALL/00-preflight.sh" ]; then
  source "$COFFEE_INSTALL/00-preflight.sh"
else
  error "Preflight checks failed. (script not found)"
  exit 1
fi
echo ""
success "Preflight checks completed"

# System phase - verify and install required base packages
section "System management"
# Phase 2: System management
if [ -f "$COFFEE_INSTALL/10-system.sh" ]; then
  source "$COFFEE_INSTALL/10-system.sh"
else
  error "System management failed. (script not found)"
  exit 1
fi

# Phase 2.1: User account verification and configuration
if [ -f "$COFFEE_INSTALL/11-user.sh" ]; then
  source "$COFFEE_INSTALL/11-user.sh"
else
  error "User verification failed. (script not found)"
  exit 1
fi

# Throw out all the exported vars since we have a new one assigned
log <<EOF
Vars log:
    COFFEE_PATH=$COFFEE_PATH
    COFFEE_INSTALL=$COFFEE_INSTALL 
    COFFEE_INSTALL_LOG_FILE=$COFFEE_INSTALL_LOG_FILE
    COFFEE_INSTALL_DEFAULTS_PATH=$COFFEE_INSTALL_DEFAULTS_PATH
  + COFFEE_DEFAULT_USER=$COFFEE_DEFAULT_USER
EOF

# Phase 2.2: Nvidia setup
if [ -f "$COFFEE_INSTALL/12-nvidia.sh" ]; then
  source "$COFFEE_INSTALL/12-nvidia.sh"
else
  error "Nvidia setup failed. (script not found)"
  exit 1
fi

# Phase 2.3: Greetd autologin setup
if [ -f "$COFFEE_INSTALL/13-greetd.sh" ]; then
  source "$COFFEE_INSTALL/13-greetd.sh"
else
  error "greetd setup failed. (script not found)"
  exit 1
fi

# Phase 2.9: Bootloader/snapper/plymouth setup
if [ -f "$COFFEE_INSTALL/19-bootloader.sh" ]; then
  source "$COFFEE_INSTALL/19-bootloader.sh"
else
  error "Bootloader setup failed. (script not found)"
  exit 1
fi
echo ""
success "System management phase complete"

# Dotfiles phase - stowing dotfiles
section "Dotfiles"
# Phase 3: Dotfiles stowing
if [ -f "$COFFEE_INSTALL/30-dotfiles.sh" ]; then
  source "$COFFEE_INSTALL/30-dotfiles.sh"
else
  error "Dotfiles stowing failed. (script not found)"
  exit 1
fi
echo ""
success "Dotfiles phase complete"

# Systemd phase - starting systemd services
section "Systemd"
# Phase 5: systemd setup
if [ -f "$COFFEE_INSTALL/50-systemd.sh" ]; then
  source "$COFFEE_INSTALL/50-systemd.sh"
else
  error "Systemd failed. (script not found)"
  exit 1
fi

# Post-installation
section "Post-installation"
if [ -f "$COFFEE_INSTALL/90-post.sh" ]; then
  source "$COFFEE_INSTALL/90-post.sh"
else
  error "Post installation failed. (script not found)"
  exit 1
fi
echo ""

if [ -f "$COFFEE_INSTALL/91-mimes.sh" ]; then
  source "$COFFEE_INSTALL/91-mimes.sh"
else
  error "Mimetype configuration failed. (script not found)"
  exit 1
fi

if [ -f "$COFFEE_INSTALL/92-firewall.sh" ]; then
  source "$COFFEE_INSTALL/92-firewall.sh"
else
  error "Firewall configuration failed. (script not found)"
  exit 1
fi

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
  2. Run the post-install script to finish (bash $COFFEE_INSTALL/install/post-install.sh)
  3. Open nvim and let Lazy sync

For more details, see:
  - Logs: $COFFEE_INSTALL_LOG_FILE
EOF
