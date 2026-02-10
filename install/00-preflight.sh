#!/bin/bash

log "Validating required components..."

# Array to track missing components
missing_components=()

# Must be x86 only to fully work
log "Checking that system is x86_64"
if [ "$(uname -m)" = "x86_64" ]; then
  success "x86_64 CPU"
else
  error "Not an x86_64 CPU"
  exit 1
fi

# Must have secure boot disabled
log "Check secure boot is disabled"
if bootctl status 2>/dev/null | grep -q 'Secure Boot: enabled'; then
  error "Secure boot needs to be disabled"
  exit 1
else
  success "Secure boot is disabled"
fi

log "Checking for pacman..."
if command_exists pacman; then
  success "pacman found"
else
  error "Imagine not being on arch"
  exit 1
fi

log "Checking for systemd..."
if command_exists systemctl; then
  success "systemd found"
else
  error "systemd not found - this is required!"
  exit 1
fi

# Check for sudo access
log "Checking for sudo access..."
if sudo -n true 2>/dev/null; then
  success "sudo access confirmed (no password required)"
elif sudo -v 2>/dev/null; then
  success "sudo access confirmed"
else
  error "No sudo access - required for system configuration"
  exit 1
fi

log "Checking for limine bootloader..."
if command_exists limine; then
  success "limine bootloader found"
else
  warn "limine bootloader not found"
  missing_components+=("limine")
fi

log "Checking for Btrfs filesystem tools..."
if command_exists btrfs; then
  success "Btrfs tools found"
else
  warn "Btrfs tools not found"
  missing_components+=("btrfs-progs")
fi

log "Checking for LUKS support..."
if command_exists cryptsetup; then
  success "LUKS support found"
else
  warn "cryptsetup not found"
  missing_components+=("cryptsetup")
fi

echo ""
if [ ${#missing_components[@]} -gt 0 ]; then
  error "The following components are missing and installation cannot continue"
  error "Missing components: [$(printf '%s, ' "${missing_components[@]}" | sed 's/, $//')]"
  exit 1
fi

# Temporarily disable mkinitcpio hooks to prevent multiple regenerations during package installation
# This speeds up installation significantly
log "Temporarily disabling mkinitcpio hooks during installation..."

# Move the specific mkinitcpio pacman hooks out of the way if they exist
if [ -f /usr/share/libalpm/hooks/90-mkinitcpio-install.hook ]; then
  sudo mv /usr/share/libalpm/hooks/90-mkinitcpio-install.hook /usr/share/libalpm/hooks/90-mkinitcpio-install.hook.disabled
fi

if [ -f /usr/share/libalpm/hooks/60-mkinitcpio-remove.hook ]; then
  sudo mv /usr/share/libalpm/hooks/60-mkinitcpio-remove.hook /usr/share/libalpm/hooks/60-mkinitcpio-remove.hook.disabled
fi

log "mkinitcpio hooks disabled"
