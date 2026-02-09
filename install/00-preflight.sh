#!/bin/bash

section "Preflight checks"

log "Validating required components..."

# Array to track missing components
missing_components=()

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
fi

# Check for sudo access
log "Checking for sudo access..."
if sudo -n true 2>/dev/null; then
  success "sudo access confirmed (no password required)"
elif sudo -v 2>/dev/null; then
  success "sudo access confirmed"
else
  error "No sudo access - required for system configuration"
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
  warn "The following components are missing and installation cannot continue"
  error "Missing components: [$(printf '%s, ' "${missing_components[@]}" | sed 's/, $//')]"
else
  success "Preflight checks completed"
fi
