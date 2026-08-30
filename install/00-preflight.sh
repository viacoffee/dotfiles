#!/bin/bash

log "Validating required components..."

if ((EUID == 0)); then
  error "Run the installer as a normal user, not as root or through sudo"
  return 1
fi

DOTFILES_DEFAULT_UID=$(id -u)
DOTFILES_DEFAULT_USER=$(id -un)
passwd_entry=$(getent passwd "$DOTFILES_DEFAULT_UID")
if [[ -z $passwd_entry ]]; then
  error "No passwd entry found for uid $DOTFILES_DEFAULT_UID"
  return 1
fi
IFS=: read -r passwd_user _ passwd_uid _ _ passwd_home _ <<< "$passwd_entry"

if [[ $passwd_user != "$DOTFILES_DEFAULT_USER" || $passwd_uid != "$DOTFILES_DEFAULT_UID" ]]; then
  error "Current user does not match the passwd database entry"
  return 1
fi
if [[ $HOME != "$passwd_home" ]]; then
  error "HOME is $HOME, but the passwd database specifies $passwd_home"
  return 1
fi
if [[ ! -d $HOME || ! -w $HOME || ! -O $HOME ]]; then
  error "Home directory must exist, be writable, and be owned by $DOTFILES_DEFAULT_USER: $HOME"
  return 1
fi

expected_runtime_dir="/run/user/$DOTFILES_DEFAULT_UID"
if [[ ${XDG_RUNTIME_DIR:-} != "$expected_runtime_dir" ]]; then
  error "XDG_RUNTIME_DIR must be $expected_runtime_dir"
  return 1
fi
if [[ ! -d $XDG_RUNTIME_DIR || ! -w $XDG_RUNTIME_DIR || ! -O $XDG_RUNTIME_DIR ]]; then
  error "Runtime directory must exist, be writable, and be owned by $DOTFILES_DEFAULT_USER"
  return 1
fi

export DOTFILES_DEFAULT_UID DOTFILES_DEFAULT_USER
export DOTFILES_USER_HOME="$passwd_home"
success "User context confirmed: $DOTFILES_DEFAULT_USER ($DOTFILES_DEFAULT_UID)"

# Must be x86 only to fully work
log "Checking that system is x86_64"
if [[ "$(uname -m)" = "x86_64" ]]; then
  success "x86_64 CPU"
else
  error "Not an x86_64 CPU"
  return 1
fi

# Must have secure boot disabled
log "Check secure boot is disabled"
if bootctl status 2>/dev/null | grep -q 'Secure Boot: enabled'; then
  error "Secure boot needs to be disabled"
  return 1
else
  success "Secure boot is disabled"
fi

log "Checking for pacman..."
if command_exists pacman; then
  success "pacman found"
else
  error "Imagine not being on arch"
  return 1
fi

log "Checking for systemd..."
if command_exists systemctl; then
  success "systemd found"
else
  error "systemd not found - this is required!"
  return 1
fi

log "Checking that the user systemd manager is reachable..."
if systemctl --user show-environment >/dev/null 2>&1; then
  success "User systemd manager is reachable"
else
  error "User systemd manager is not reachable"
  return 1
fi

# Check for sudo access
log "Checking for sudo access..."
if sudo -n true 2>/dev/null; then
  success "sudo access confirmed (no password required)"
elif sudo -v 2>/dev/null; then
  success "sudo access confirmed"
else
  error "No sudo access - required for system configuration"
  return 1
fi

log "Checking for limine bootloader..."
if command_exists limine; then
  success "limine bootloader found"
else
  error "limine bootloader not found"
  return 1
fi

log "Checking for Btrfs filesystem tools..."
if command_exists btrfs; then
  success "Btrfs tools found"
else
  error "Btrfs tools not found"
  return 1
fi

log "Checking for LUKS support..."
if command_exists cryptsetup; then
  success "LUKS support found"
else
  error "cryptsetup not found"
  return 1
fi
