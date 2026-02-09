#!/bin/bash

# Limine bootloader
# Implements Omarchy pattern for Limine setup with kernel parameter extraction

log "Configuring Limine bootloader..."

# Check one more time to see if limine is installed
log "Checking for limine bootloader..."
if command_exists limine; then
  success "limine bootloader found"
else
  error "limine bootloader not found"
fi

# Check if limine-mkinitcpio-hook is installed
if ! command_exists limine-mkinitcpio; then
  error "limine-mkinitcpio-hook not found. Install with: sudo pacman -S limine-mkinitcpio-hook"
fi

# Check if limine-snapper-sync is installed
if ! command_exists limine-snapper-sync; then
  error "limine-mkinitcpio-hook not found. Install with: sudo pacman -S limine-snapper-sync"
fi

# Step 1: Extract existing kernel command line from bootloader config
log "Extracting kernel command line from existing bootloader config..."

sudo tee /etc/mkinitcpio.conf.d/coffee_hooks.conf <<EOF >/dev/null
HOOKS=(base udev plymouth keyboard autodetect microcode modconf kms keymap consolefont block encrypt lvm2 filesystems fsck btrfs-overlayfs)
EOF

# Detect boot mode
if [[ -d /sys/firmware/efi ]]; then
  EFI=true
else
  error "Not EFI system"
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
fi
success "Limine config: $limine_config"

CMDLINE=$(grep "^[[:space:]]*cmdline:" "$limine_config" | head -1 | sed 's/^[[:space:]]*cmdline:[[:space:]]*//')
log "Limine cmdline: $CMDLINE"

# TODO-david DUPLICATING ===================

sudo cp $COFFEE_INSTALL_DEFAULTS_PATH/limine/default.conf /etc/default/limine
sudo sed -i "s|@@CMDLINE@@|$CMDLINE|g" /etc/default/limine

# UKI and EFI fallback are EFI only
if [[ -z $EFI ]]; then
  sudo sed -i '/^ENABLE_UKI=/d; /^ENABLE_LIMINE_FALLBACK=/d' /etc/default/limine
fi

# Remove the original config file if it's not /boot/limine.conf
if [[ "$limine_config" != "/boot/limine.conf" ]] && [[ -f "$limine_config" ]]; then
  sudo rm "$limine_config"
fi

# We overwrite the whole thing knowing the limine-update will add the entries for us
sudo cp $COFFEE_INSTALL_DEFAULTS_PATH/limine/limine.conf /boot/limine.conf

# Match Snapper configs
if ! sudo snapper list-configs 2>/dev/null | grep -q "root"; then
  sudo snapper -c root create-config /
fi

if ! sudo snapper list-configs 2>/dev/null | grep -q "home"; then
  sudo snapper -c home create-config /home
fi

# Enable quota to allow space-aware algorithms to work
sudo btrfs quota enable /

# Tweak default Snapper configs
sudo sed -i 's/^TIMELINE_CREATE="yes"/TIMELINE_CREATE="no"/' /etc/snapper/configs/{root,home}
sudo sed -i 's/^NUMBER_LIMIT="50"/NUMBER_LIMIT="5"/' /etc/snapper/configs/{root,home}
sudo sed -i 's/^NUMBER_LIMIT_IMPORTANT="10"/NUMBER_LIMIT_IMPORTANT="5"/' /etc/snapper/configs/{root,home}
sudo sed -i 's/^SPACE_LIMIT="0.5"/SPACE_LIMIT="0.3"/' /etc/snapper/configs/{root,home}
sudo sed -i 's/^FREE_LIMIT="0.2"/FREE_LIMIT="0.3"/' /etc/snapper/configs/{root,home}

sudo systemctl enable limine-snapper-sync

log "Re-enabling mkinitcpio hooks"
# Restore the specific mkinitcpio pacman hooks
if [ -f /usr/share/libalpm/hooks/90-mkinitcpio-install.hook.disabled ]; then
  sudo mv /usr/share/libalpm/hooks/90-mkinitcpio-install.hook.disabled /usr/share/libalpm/hooks/90-mkinitcpio-install.hook
fi

if [ -f /usr/share/libalpm/hooks/60-mkinitcpio-remove.hook.disabled ]; then
  sudo mv /usr/share/libalpm/hooks/60-mkinitcpio-remove.hook.disabled /usr/share/libalpm/hooks/60-mkinitcpio-remove.hook
fi
success "mkinitcpio hooks re-enabled"

sudo limine-update

if [[ -n $EFI ]] && efibootmgr &>/dev/null; then
    # Remove the archinstall-created Limine entry
  while IFS= read -r bootnum; do
    sudo efibootmgr -b "$bootnum" -B >/dev/null 2>&1
  done < <(efibootmgr | grep -E "^Boot[0-9]{4}\*? Arch Linux Limine" | sed 's/^Boot\([0-9]\{4\}\).*/\1/')
fi

if [ "$(plymouth-set-default-theme)" != "coffee" ]; then
  sudo cp -r "$COFFEE_INSTALL_DEFAULTS_PATH/plymouth" /usr/share/plymouth/themes/coffee/
  sudo plymouth-set-default-theme coffee
fi

#
# limine_possible_locations=(
#   /boot/EFI/arch-limine/limine.conf
#   /boot/EFI/BOOT/limine.conf
#   /boot/EFI/limine/limine.conf
#   /boot/limine/limine.conf
#   /boot/limine.conf
# )
# limine_config=""
# for path in $limine_possible_locations; do
#   if [ -f "$path" ]; then
#     log "Found Limine config at: $path"
#     $limine_config="$path"
#     break
#   fi
# done
#
# # Extract kernel command line
# if [ -n "$limine_config" ]; then
#   # Look for linux_cmdline or cmdline in Limine config
#   $cmdline=$(grep -E "^\s*(linux_cmdline|cmdline):" "$limine_config" 2>/dev/null | head -1 | sed -E 's/^\s*(linux_cmdline|cmdline):\s*//')
#
#   if [ -z "$cmdline" ]; then
#     warn "Could not extract kernel command line from bootloader"
#     log "Will use empty command line (only quiet splash will be added)"
#     $cmdline=""
#   else
#     log "Extracted kernel command line: $cmdline"
#   fi
# else
#   warn "No existing Limine configuration found"
#   log "Searched paths:"
#   for path in $limine_possible_locations; do
#     log "  - $path"
#   done
#   $cmdline=""
# fi
#
#if command -v limine &>/dev/null; then
#  sudo tee /etc/mkinitcpio.conf.d/coffee.conf >/dev/null <<'EOF'
#HOOKS=(base udev plymouth keyboard autodetect microcode modconf kms keymap consolefont block encrypt filesystems fsck btrfs-overlayfs)
#EOF
#
#  # Regenerate initramfs with required modules
#  echo "Regenerating initramfs with required modules..."
#
#  if ! sudo mkinitcpio -P; then
#    echo "Failed to regenerate initramfs"
#    exit 1
#  fi
#fi
#
## Enable quota to allow space-aware algorithms to work
#sudo btrfs quota enable /
#
## Tweak default Snapper configs
#sudo sed -i 's/^TIMELINE_CREATE="yes"/TIMELINE_CREATE="no"/' /etc/snapper/configs/{root,home}
#sudo sed -i 's/^NUMBER_LIMIT="50"/NUMBER_LIMIT="5"/' /etc/snapper/configs/{root,home}
#sudo sed -i 's/^NUMBER_LIMIT_IMPORTANT="10"/NUMBER_LIMIT_IMPORTANT="5"/' /etc/snapper/configs/{root,home}
#sudo sed -i 's/^SPACE_LIMIT="0.5"/SPACE_LIMIT="0.3"/' /etc/snapper/configs/{root,home}
#sudo sed -i 's/^FREE_LIMIT="0.2"/FREE_LIMIT="0.3"/' /etc/snapper/configs/{root,home}
#
## Update limine
#sudo limine-update
#
## Default plymouth theme
#sudo plymouth-set-default-theme tribar
