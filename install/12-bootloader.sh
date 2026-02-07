#!/usr/bin/env bash
set -euo pipefail

if command -v limine &>/dev/null; then
  sudo tee /etc/mkinitcpio.conf.d/coffee.conf >/dev/null <<'EOF'
HOOKS=(base udev plymouth keyboard autodetect microcode modconf kms keymap consolefont block encrypt filesystems fsck btrfs-overlayfs)
EOF

  # Regenerate initramfs with required modules
  echo "Regenerating initramfs with required modules..."

  if ! sudo mkinitcpio -P; then
    echo "Failed to regenerate initramfs"
    exit 1
  fi
fi

# Enable quota to allow space-aware algorithms to work
sudo btrfs quota enable /

# Tweak default Snapper configs
sudo sed -i 's/^TIMELINE_CREATE="yes"/TIMELINE_CREATE="no"/' /etc/snapper/configs/{root,home}
sudo sed -i 's/^NUMBER_LIMIT="50"/NUMBER_LIMIT="5"/' /etc/snapper/configs/{root,home}
sudo sed -i 's/^NUMBER_LIMIT_IMPORTANT="10"/NUMBER_LIMIT_IMPORTANT="5"/' /etc/snapper/configs/{root,home}
sudo sed -i 's/^SPACE_LIMIT="0.5"/SPACE_LIMIT="0.3"/' /etc/snapper/configs/{root,home}
sudo sed -i 's/^FREE_LIMIT="0.2"/FREE_LIMIT="0.3"/' /etc/snapper/configs/{root,home}

# Update limine
sudo limine-update

# Default plymouth theme
sudo plymouth-set-default-theme tribar
