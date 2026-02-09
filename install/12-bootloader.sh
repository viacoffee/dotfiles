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

# Step 1: Extract existing kernel command line from bootloader config
log "Extracting kernel command line from existing bootloader config..."

limine_possible_locations=(
  /boot/EFI/arch-limine/limine.conf
  /boot/EFI/BOOT/limine.conf
  /boot/EFI/limine/limine.conf
  /boot/limine/limine.conf
  /boot/limine.conf
)
limine_config=""
for path in limine_possible_locations; do
  if [ -f "$path" ]; then
    log "Found Limine config at: $path"
    limine_config="$path"
    break
  fi
done

# Extract kernel command line
if [ -n "$limine_config" ]; then
  # Look for linux_cmdline or cmdline in Limine config
  cmdline=$(grep -E "^\s*(linux_cmdline|cmdline):" "$limine_config" 2>/dev/null | head -1 | sed -E 's/^\s*(linux_cmdline|cmdline):\s*//')
  
  if [ -z "$cmdline" ]; then
    warn "Could not extract kernel command line from bootloader"
    log "Will use empty command line (only quiet splash will be added)"
    cmdline=""
  else
    log "Extracted kernel command line: $cmdline"
  fi
else
  warn "No existing Limine configuration found"
  log "Searched paths:"
  for path in limine_possible_locations; do
    log "  - $path"
  done
  cmdline=""
fi

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
