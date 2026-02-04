##!/usr/bin/env bash
#set -euo pipefail
#
## Detect EFI partition
#EFI_PART=$(lsblk -no MOUNTPOINT,FSTYPE | grep "vfat" | awk '{print $1}' | head -1)
#
#if [ -z "$EFI_PART" ]; then
#  echo "Warning: Could not automatically detect EFI partition. Skipping bootloader installation."
#  echo "Please manually run: sudo limine-deploy /path/to/device"
#  exit 0
#fi
#
## Get the device from the mount point
#EFI_DEVICE=$(lsblk -no PKNAME $(lsblk -no KNAME -l | grep "$(basename $(mount | grep "$EFI_PART" | awk '{print $1}') | sed 's/[0-9]*$//g')" | head -1))
#
#if [ -n "$EFI_DEVICE" ]; then
#  echo "Installing limine bootloader to /dev/$EFI_DEVICE"
#  sudo limine-deploy "/dev/$EFI_DEVICE" || {
#    echo "Warning: Limine installation failed. The system may need manual bootloader configuration."
#    echo "See https://github.com/limine-bootloader/limine for manual installation steps."
#  }
#else
#  echo "Warning: Could not determine boot device. Skipping bootloader installation."
#  echo "Please manually run: sudo limine-deploy /path/to/device"
#fi
