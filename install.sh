#!/bin/bash

set -eEuo pipefail

if ((EUID == 0)); then
  echo "Error: run install.sh as a normal user, not as root or through sudo." >&2
  exit 1
fi

if [[ -z "${DOTFILES_PATH:-}" ]]; then
  DOTFILES_PATH=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
  export DOTFILES_PATH
fi

if [[ "$(pwd)" != "$DOTFILES_PATH" ]]; then
  echo "Error: install.sh must be run from the dotfiles root ($DOTFILES_PATH)"
  exit 1
fi

if [[ -z "${DOTFILES_INSTALL:-}" ]]; then
  export DOTFILES_INSTALL="$DOTFILES_PATH/install"
fi

export DOTFILES_INSTALL_DEFAULTS_PATH="$DOTFILES_INSTALL/default"
export DOTFILES_INSTALL_LOG_FILE="${DOTFILES_INSTALL_LOG_FILE:-$HOME/.local/state/dotfiles/install.log}"
export DOTFILES_INSTALL_RUN_ID="${DOTFILES_INSTALL_RUN_ID:-$(date '+%Y%m%dT%H%M%S')-$$}"
export DOTFILES_INSTALL_TRACE_FILE="${DOTFILES_INSTALL_TRACE_FILE:-$DOTFILES_INSTALL_LOG_FILE.$DOTFILES_INSTALL_RUN_ID.trace}"
export DOTFILES_CURRENT_PHASE="startup"

# Ensure log files exist and keep the command trace private to the current user.
mkdir -p "$(dirname "$DOTFILES_INSTALL_LOG_FILE")" 2>/dev/null || true
touch "$DOTFILES_INSTALL_LOG_FILE" "$DOTFILES_INSTALL_TRACE_FILE"
chmod 600 "$DOTFILES_INSTALL_TRACE_FILE"
exec 19>>"$DOTFILES_INSTALL_TRACE_FILE"
export BASH_XTRACEFD=19
export PS4='+ ${BASH_SOURCE##*/}:${LINENO}: '
set -x

# Source helper functions FIRST (before any function calls)
if [[ ! -f "$DOTFILES_INSTALL/lib/helpers.sh" ]]; then
  echo "Error: Helper functions not found at $DOTFILES_INSTALL/lib/helpers.sh"
  exit 1
fi
# shellcheck source=install/lib/helpers.sh
source "$DOTFILES_INSTALL/lib/helpers.sh"

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

DOTFILES_ERROR_REPORTED=0
_install_error() {
  local status=$1
  local line=$2
  local command=$3

  if ((DOTFILES_ERROR_REPORTED == 0)); then
    DOTFILES_ERROR_REPORTED=1
    error "Installation failed: run=$DOTFILES_INSTALL_RUN_ID phase=$DOTFILES_CURRENT_PHASE status=$status line=$line command=$command"
  fi
  return "$status"
}
trap '_install_error "$?" "$LINENO" "$BASH_COMMAND"' ERR

# Source a numbered install phase script or exit
run_phase() {
  local script="$DOTFILES_INSTALL/$1"
  local title="${2:-$1}"
  export DOTFILES_CURRENT_PHASE="$1"
  if [[ ! -f "$script" ]]; then
    error "Phase script not found: $script"
    exit 1
  fi
  section "$title"
  info "Running $1"
  log "Phase context: run=$DOTFILES_INSTALL_RUN_ID phase=$1 user=$(id -un) uid=$(id -u) euid=$EUID pwd=$PWD"
  # shellcheck disable=SC1090 # numbered phase paths are validated immediately above
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

info "Installing system from: $DOTFILES_PATH"
important "Logfile: $DOTFILES_INSTALL_LOG_FILE"
log <<EOF
Vars log:
  + DOTFILES_PATH=$DOTFILES_PATH
  + DOTFILES_INSTALL=$DOTFILES_INSTALL
  + DOTFILES_INSTALL_LOG_FILE=$DOTFILES_INSTALL_LOG_FILE
  + DOTFILES_INSTALL_DEFAULTS_PATH=$DOTFILES_INSTALL_DEFAULTS_PATH
  + DOTFILES_INSTALL_TRACE_FILE=$DOTFILES_INSTALL_TRACE_FILE
  + DOTFILES_INSTALL_RUN_ID=$DOTFILES_INSTALL_RUN_ID
  + USER=$(id -un)
  + UID=$(id -u)
  + EUID=$EUID
  + PWD=$PWD
  + XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-<unset>}
EOF
log "Installation started at: $(date '+%Y-%m-%d %H:%M:%S')"

echo ""
log "Starting installation phases..."

run_phase "00-preflight.sh" "Preflight checks"

# System phase - install required packages
section "System management"
run_phase "10-system.sh" "Packages and repositories"
run_phase "11-user.sh" "User account"

# Log the user identity established during preflight.
log <<EOF
Vars log:
    DOTFILES_PATH=$DOTFILES_PATH
    DOTFILES_INSTALL=$DOTFILES_INSTALL
    DOTFILES_INSTALL_LOG_FILE=$DOTFILES_INSTALL_LOG_FILE
    DOTFILES_INSTALL_DEFAULTS_PATH=$DOTFILES_INSTALL_DEFAULTS_PATH
  + DOTFILES_DEFAULT_USER=${DOTFILES_DEFAULT_USER:-}
  + DOTFILES_DEFAULT_UID=${DOTFILES_DEFAULT_UID:-}
  + DOTFILES_USER_HOME=${DOTFILES_USER_HOME:-}
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
log "Checking ownership of installer-managed user state"
verify_user_ownership \
  "$HOME/.config" \
  "$HOME/.cache" \
  "$HOME/.local" \
  "$HOME/.first-login" \
  "$HOME/notes" \
  "$HOME/projects" \
  "$HOME/work"
run_phase "92-firewall.sh" "Firewall"

export DOTFILES_CURRENT_PHASE="complete"
success "Installation completed"
log "Installation finished: run=$DOTFILES_INSTALL_RUN_ID status=0"
info "Reboot to start the configured desktop session."
info "Installation log: $DOTFILES_INSTALL_LOG_FILE"
