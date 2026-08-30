#!/bin/bash

# Limine bootloader

log "Configuring Limine bootloader..."

# Check if limine-mkinitcpio-hook is installed
if ! command_exists limine-mkinitcpio; then
  error "limine-mkinitcpio-hook not found. Install with: sudo pacman -S limine-mkinitcpio-hook"
  return 1
fi

# Check if limine-snapper-sync is installed
if ! command_exists limine-snapper-sync; then
  error "limine-snapper-sync not found. Install with: sudo pacman -S limine-snapper-sync"
  return 1
fi

# This failure boundary is deliberately before any active boot configuration is
# changed, so the package-transaction recovery test retains known-good entries.
inject_install_failure before-final-limine-update

# Step 1: Extract existing kernel command line from bootloader config
log "Extracting kernel command line from existing bootloader config..."

sudo tee /etc/mkinitcpio.conf.d/dot_hooks.conf <<EOF >/dev/null
HOOKS=(base udev plymouth keyboard autodetect microcode modconf kms keymap block encrypt filesystems btrfs-overlayfs)
EOF

# Detect boot mode
if [[ ! -d /sys/firmware/efi ]]; then
  error "Not EFI system"
  return 1
fi

# Find config location. The ESP may only be readable by root.
log "Finding limine config..."
limine_config=""
for candidate in \
  /boot/EFI/arch-limine/limine.conf \
  /boot/EFI/BOOT/limine.conf \
  /boot/EFI/limine/limine.conf \
  /boot/limine/limine.conf \
  /boot/limine.conf; do
  if sudo test -f "$candidate"; then
    limine_config="$candidate"
    break
  fi
done
if [[ -z "$limine_config" ]]; then
  error "Limine config not found"
  return 1
fi
success "Limine config: $limine_config"

# Extract cmdline BEFORE we overwrite the config file
CMDLINE=$(sudo grep "^[[:space:]]*cmdline:" "$limine_config" 2>/dev/null \
  | head -1 \
  | sed 's/^[[:space:]]*cmdline:[[:space:]]*//' || true)

# If no cmdline found in current config, use a sensible default
if [[ -z "$CMDLINE" ]]; then
  warn "No cmdline found in existing config"
  warn "Manually verify limine config: $limine_config"
  return 1
fi
log "Limine cmdline: $CMDLINE"

# The managed arguments are appended by the template below. Remove existing
# occurrences first so repeated installer runs do not grow the command line.
for managed_arg in quiet splash nowatchdog plymouth.ignore-serial-consoles; do
  escaped_arg=$(printf '%s\n' "$managed_arg" | sed 's/[][\\/.^$*+?{}()|]/\\&/g')
  CMDLINE=$(printf '%s\n' "$CMDLINE" | sed -E \
    "s/(^|[[:space:]])${escaped_arg}([[:space:]]|$)/\\1\\2/g; s/[[:space:]]+/ /g; s/^ //; s/ $//")
done

CMDLINE_ESCAPED=$(printf '%s\n' "$CMDLINE" | sed 's/[&\\]/\\&/g')
sudo cp "$DOTFILES_INSTALL_DEFAULTS_PATH/limine/default.conf" /etc/default/limine
sudo sed -i "s|@@CMDLINE@@|$CMDLINE_ESCAPED|g" /etc/default/limine

# Remove the original config file if it's not /boot/limine.conf
if [[ "$limine_config" != "/boot/limine.conf" ]] && sudo test -f "$limine_config"; then
  sudo rm "$limine_config"
fi

# We overwrite the whole thing knowing the limine-update will add the entries for us
sudo cp "$DOTFILES_INSTALL_DEFAULTS_PATH/limine/limine.conf" /boot/limine.conf

# Match Snapper configs
if ! sudo snapper list-configs 2>/dev/null | grep -q "root"; then
  sudo snapper -c root create-config /
fi

if ! sudo snapper list-configs 2>/dev/null | grep -q "home"; then
  sudo snapper -c home create-config /home
fi

# Enable quota to allow space-aware algorithms to work
log "Check if btrfs quota is enabled"
if sudo btrfs quota status / | grep -qE '^\s*Enabled:\s+yes'; then
  success "Btrfs quota already enabled"
else
  sudo btrfs quota enable /
  success "Enabled btrfs quota"
fi

# Tweak default Snapper configs
sudo sed -i 's/^TIMELINE_CREATE="yes"/TIMELINE_CREATE="no"/' /etc/snapper/configs/{root,home}
sudo sed -i 's/^NUMBER_LIMIT="50"/NUMBER_LIMIT="5"/' /etc/snapper/configs/{root,home}
sudo sed -i 's/^NUMBER_LIMIT_IMPORTANT="10"/NUMBER_LIMIT_IMPORTANT="5"/' /etc/snapper/configs/{root,home}
sudo sed -i 's/^SPACE_LIMIT="0.5"/SPACE_LIMIT="0.3"/' /etc/snapper/configs/{root,home}
sudo sed -i 's/^FREE_LIMIT="0.2"/FREE_LIMIT="0.3"/' /etc/snapper/configs/{root,home}

# Blacklist hardware watchdog modules (desktop, not needed)
log "Blacklisting hardware watchdog modules..."
sudo mkdir -p /etc/modprobe.d
sudo cp "$DOTFILES_INSTALL_DEFAULTS_PATH/modprobe/nowatchdog.conf" /etc/modprobe.d/nowatchdog.conf

log "Checking plymouth theme configuration..."
plymouth_theme_dir=/usr/share/plymouth/themes/dot
if sudo test -d "$plymouth_theme_dir/plymouth"; then
  run_logged "Removing nested Plymouth theme directory" \
    sudo rm -rf "$plymouth_theme_dir/plymouth"
fi
run_logged "Creating Plymouth theme directory" \
  sudo install -d "$plymouth_theme_dir"
run_logged "Copying Plymouth theme contents" \
  sudo cp -a "$DOTFILES_INSTALL_DEFAULTS_PATH/plymouth/." "$plymouth_theme_dir/"

if [[ "$(plymouth-set-default-theme)" != "dot" ]]; then
  run_logged "Setting default theme" \
    sudo plymouth-set-default-theme dot
fi
success "Plymouth theme configuration is set"

# Disable default mkinitcpio UKI generation
log "Disabling default mkinitcpio UKI preset..."
preset="/etc/mkinitcpio.d/linux.preset"
if [[ -f "$preset" ]] && grep -q '^default_uki=' "$preset"; then
  sudo sed -i 's/^default_uki=/#default_uki=/' "$preset"
  sudo sed -i 's/^fallback_uki=/#fallback_uki=/' "$preset"
  sudo sed -i 's/^default_options=/#default_options=/' "$preset"
  success "Disabled default UKI in mkinitcpio preset"
fi

# Clean up stale UKIs that were generated by the default preset
log "Clean stale UKIs..."
for stale in /boot/EFI/Linux/arch-linux.efi /boot/EFI/Linux/arch-linux-fallback.efi; do
  if sudo test -f "$stale"; then
    run_logged "Removing stale UKI: $stale" \
      sudo rm "$stale"
  fi
done

expected_uki=/boot/EFI/Linux/dot_linux.efi
uki_state_before=$(sudo stat -c '%s:%y' "$expected_uki" 2>/dev/null || true)
run_logged "Running authoritative final Limine generation" \
  sudo limine-update
inject_install_failure after-final-limine-update

log "Validating final Limine and UKI artifacts"
if ! sudo test -s /boot/limine.conf; then
  error "Final Limine configuration is missing or empty"
  return 1
fi
if ! sudo grep -Fq 'dot_linux.efi' /boot/limine.conf; then
  error "Final Limine configuration does not reference the expected UKI"
  return 1
fi
if ! sudo test -s "$expected_uki"; then
  error "Expected UKI is missing or empty: $expected_uki"
  return 1
fi
uki_state_after=$(sudo stat -c '%s:%y' "$expected_uki")
if [[ -n $uki_state_before && $uki_state_after == "$uki_state_before" ]]; then
  error "Final Limine generation did not refresh the expected UKI"
  return 1
fi

initramfs_listing=$(sudo lsinitcpio -l "$expected_uki")
for required_command in cryptsetup plymouth btrfs; do
  if ! grep -Eq "(^|/)${required_command}$" <<< "$initramfs_listing"; then
    error "Final UKI does not contain: $required_command"
    return 1
  fi
done

if [[ -f /etc/mkinitcpio.conf.d/nvidia.conf ]]; then
  for required_module in nvidia nvidia_modeset nvidia_uvm nvidia_drm; do
    if ! grep -Eq "(^|/)${required_module}(\\.ko(\\.[a-z0-9]+)?)?$" <<< "$initramfs_listing"; then
      error "Final UKI does not contain NVIDIA module: $required_module"
      return 1
    fi
  done
fi
success "Final Limine configuration and UKI validated"

remove_pacman_generation_override
inject_install_failure after-final-generation
