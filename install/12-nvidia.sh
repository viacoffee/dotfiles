#!/bin/bash

# Detect NVIDIA GPU with error handling
NVIDIA=""
if ! NVIDIA="$(lspci | grep -i 'nvidia')" 2>/dev/null; then
  warn "Failed to query GPU info (lspci not available or error occurred)"
  NVIDIA=""
fi

if [[ -z "$NVIDIA" ]]; then
  warn "No NVIDIA GPU detected. Skipping NVIDIA driver installation."
  return 0
fi

info "NVIDIA GPU detected: $NVIDIA"

# Detect kernel type and set appropriate headers package
KERNEL_HEADERS=""
if pacman -Qqs '^linux-zen$' &>/dev/null; then
  KERNEL_HEADERS="linux-zen-headers"
elif pacman -Qqs '^linux-lts$' &>/dev/null; then
  KERNEL_HEADERS="linux-lts-headers"
elif pacman -Qqs '^linux-hardened$' &>/dev/null; then
  KERNEL_HEADERS="linux-hardened-headers"
elif pacman -Qqs '^linux$' &>/dev/null; then
  KERNEL_HEADERS="linux-headers"
else
  error "No supported kernel detected"
  exit 1
fi

info "Detected kernel headers package: $KERNEL_HEADERS"

# Determine driver packages based on GPU model
PACKAGES=()

if echo "$NVIDIA" | grep -qE "RTX [2-9][0-9]|GTX 16"; then
  # Turing (16xx, 20xx), Ampere (30xx), Ada (40xx), and newer recommend the open-source kernel modules
  info "Detected modern NVIDIA GPU (RTX 20xx+). Using open-source drivers."
  PACKAGES=(nvidia-open-dkms nvidia-utils lib32-nvidia-utils libva-nvidia-driver)
elif echo "$NVIDIA" | grep -qE "GTX 9|GTX 10|Quadro P|MX1|MX2|MX3"; then
  # Pascal (10xx, Quadro Pxxx, MX150, MX2xx, MX3xx) and Maxwell (9xx, MX110, MX130) use legacy drivers
  info "Detected legacy NVIDIA GPU (Maxwell/Pascal). Using legacy drivers (580xx)."
  PACKAGES=(nvidia-580xx-dkms nvidia-580xx-utils lib32-nvidia-580xx-utils)
else
  warn "NVIDIA GPU detected but no compatible driver found."
  warn "For more information, see: https://wiki.archlinux.org/title/NVIDIA"
  exit 0
fi

info "Packages to be installed: ${PACKAGES[*]}"

# Install packages
log "Installing NVIDIA drivers and dependencies..."
INSTALL_PACKAGES=("$KERNEL_HEADERS" "${PACKAGES[@]}")
if ! sudo pacman -S --needed --noconfirm "${INSTALL_PACKAGES[@]}"; then
  error "Failed to install NVIDIA packages"
  exit 1
fi
success "Package installation completed successfully"

# Configure modprobe for early KMS
log "Configuring modprobe for NVIDIA early KMS..."
if ! sudo mkdir -p /etc/modprobe.d; then
  error "Failed to create modprobe.d directory"
  exit 1
fi

if ! sudo tee /etc/modprobe.d/nvidia.conf >/dev/null <<'EOF'
options nvidia_drm modeset=1
EOF
then
  error "Failed to write modprobe configuration"
  exit 1
fi

# Configure mkinitcpio for early module loading
log "Configuring mkinitcpio for NVIDIA modules..."
if ! sudo mkdir -p /etc/mkinitcpio.conf.d; then
  error "Failed to create mkinitcpio.conf.d directory"
  exit 1
fi

if ! sudo tee /etc/mkinitcpio.conf.d/nvidia.conf >/dev/null <<'EOF'
MODULES+=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)
EOF
then
  error "Failed to write mkinitcpio configuration"
  exit 1
fi

# Regenerate initramfs with NVIDIA modules
log "Regenerating initramfs with NVIDIA modules..."
if ! sudo mkinitcpio -P; then
  error "Failed to regenerate initramfs"
  exit 1
fi

# Set NVIDIA environment variables for Wayland/Niri
log "Configuring NVIDIA environment variables..."
if ! mkdir -p ~/.config/environment.d; then
  error "Failed to create environment.d directory"
  exit 1
fi

if ! cat >> ~/.config/environment.d/nvidia.conf <<'EOF'
# NVIDIA drivers for Wayland/Niri
NVD_BACKEND=direct
LIBVA_DRIVER_NAME=nvidia
__GLX_VENDOR_LIBRARY_NAME=nvidia
EOF
then
  error "Failed to write environment configuration"
  exit 1
fi

success "NVIDIA drivers configured successfully."
warn "Note: System reboot may be required for changes to take effect."
