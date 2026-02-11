#!/usr/bin/env bash
set -euo pipefail

echo "=== LIMINE BOOT DEBUG ==="
echo

echo "== System =="
echo "Hostname: $(hostname)"
echo "Kernel: $(uname -r)"
echo "Boot mode:"
if [ -d /sys/firmware/efi ]; then
  echo "  UEFI"
else
  echo "  BIOS/Legacy"
fi
echo

echo "== Mounts =="
findmnt /boot /boot/efi 2>/dev/null || echo "No /boot or /boot/efi mount found"
echo

echo "== Searching for limine.conf =="
find /boot -name "limine.conf" 2>/dev/null || echo "No limine.conf found"
echo

echo "== /boot Contents =="
ls -lah /boot || echo "Cannot read /boot"
echo

echo "== /boot/EFI Contents =="
if [ -d /boot/EFI ]; then
  ls -lah /boot/EFI
else
  echo "/boot/EFI does not exist"
fi
echo

echo "== Kernel Images =="
ls -lah /boot | grep -E "vmlinuz|initramfs|uki|efi" || echo "No kernel/initramfs/EFI images found"
echo

echo "== UKI Directory (/boot/EFI/Linux) =="
if [ -d /boot/EFI/Linux ]; then
  ls -lah /boot/EFI/Linux
else
  echo "No /boot/EFI/Linux directory"
fi
echo

echo "== limine.conf (if found) =="
for f in $(find /boot -name "limine.conf" 2>/dev/null); do
  echo "--- $f ---"
  sed 's/^/    /' "$f"
  echo
done

echo "== Block Devices (UUIDs) =="
blkid || echo "blkid failed"
echo

echo "== Limine EFI Files =="
find /boot -iname "*limine*.efi" 2>/dev/null || echo "No limine EFI files found"
echo

echo "=== END ==="
