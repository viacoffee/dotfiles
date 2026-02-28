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

# Step 1: Extract existing kernel command line from bootloader config
log "Extracting kernel command line from existing bootloader config..."

sudo tee /etc/mkinitcpio.conf.d/coffee_hooks.conf <<EOF >/dev/null
HOOKS=(base udev plymouth keyboard autodetect microcode modconf kms keymap consolefont block encrypt filesystems fsck btrfs-overlayfs)
EOF

# Detect boot mode
if [[ ! -d /sys/firmware/efi ]]; then
  error "Not EFI system"
  return 1
fi

# Find config location
log "Finding limine config..."
if [[ -f /boot/EFI/arch-limine/limine.conf ]]; then
  limine_config="/boot/EFI/arch-limine/limine.conf"
elif [[ -f /boot/EFI/BOOT/limine.conf ]]; then
  limine_config="/boot/EFI/BOOT/limine.conf"
elif [[ -f /boot/EFI/limine/limine.conf ]]; then
  limine_config="/boot/EFI/limine/limine.conf"
elif [[ -f /boot/limine/limine.conf ]]; then
  limine_config="/boot/limine/limine.conf"
elif [[ -f /boot/limine.conf ]]; then
  limine_config="/boot/limine.conf"
else
  error "Limine config not found"
  return 1
fi
success "Limine config: $limine_config"

# Extract cmdline BEFORE we overwrite the config file
CMDLINE=$(grep "^[[:space:]]*cmdline:" "$limine_config" | head -1 | sed 's/^[[:space:]]*cmdline:[[:space:]]*//')

# If no cmdline found in current config, use a sensible default
if [[ -z "$CMDLINE" ]]; then
  warn "No cmdline found in existing config"
  warn "Manually verify limine config: $limine_config"
  return 1
fi
log "Limine cmdline: $CMDLINE"

CMDLINE_ESCAPED=$(printf '%s\n' "$CMDLINE" | sed 's/[&\\]/\\&/g')
sudo cp "$COFFEE_INSTALL_DEFAULTS_PATH/limine/default.conf" /etc/default/limine
sudo sed -i "s|@@CMDLINE@@|$CMDLINE_ESCAPED|g" /etc/default/limine

# Remove the original config file if it's not /boot/limine.conf
if [[ "$limine_config" != "/boot/limine.conf" ]] && [[ -f "$limine_config" ]]; then
  sudo rm "$limine_config"
fi

# We overwrite the whole thing knowing the limine-update will add the entries for us
sudo cp "$COFFEE_INSTALL_DEFAULTS_PATH/limine/limine.conf" /boot/limine.conf

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

log "Checking plymouth theme configuration..."
if [[ "$(plymouth-set-default-theme)" != "coffee" ]]; then
  run_logged "Copying plymouth theme" \
    sudo cp -r "$COFFEE_INSTALL_DEFAULTS_PATH/plymouth" /usr/share/plymouth/themes/coffee/

  run_logged "Setting default theme" \
    sudo plymouth-set-default-theme coffee
fi
success "Plymouth theme configuration is set"

#if [[ -n $EFI ]] && efibootmgr &>/dev/null; then
#    # Remove the archinstall-created Limine entry
#  while IFS= read -r bootnum; do
#    sudo efibootmgr -b "$bootnum" -B >/dev/null 2>&1
#  done < <(efibootmgr | grep -E "^Boot[0-9]{4}\*? Arch Linux Limine" | sed 's/^Boot\([0-9]\{4\}\).*/\1/')
#fi

log "Re-enabling mkinitcpio hooks"
# Restore the specific mkinitcpio pacman hooks
if [[ -f /usr/share/libalpm/hooks/90-mkinitcpio-install.hook.disabled ]]; then
  sudo mv /usr/share/libalpm/hooks/90-mkinitcpio-install.hook.disabled /usr/share/libalpm/hooks/90-mkinitcpio-install.hook
fi

if [[ -f /usr/share/libalpm/hooks/60-mkinitcpio-remove.hook.disabled ]]; then
  sudo mv /usr/share/libalpm/hooks/60-mkinitcpio-remove.hook.disabled /usr/share/libalpm/hooks/60-mkinitcpio-remove.hook
fi
success "mkinitcpio hooks re-enabled"

run_logged "Running limine-update" \
  sudo limine-update
