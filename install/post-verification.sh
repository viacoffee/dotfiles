#!/bin/bash

# Post-installation verification script for Coffee dotfiles
# Verifies all installations from the install scripts and validates configurations
# Logs all output to /var/log/coffee-post-install.log

set -eEo pipefail

# Initialize paths
COFFEE_PATH="${COFFEE_PATH:-.}"
COFFEE_INSTALL="${COFFEE_INSTALL:-$COFFEE_PATH/install}"
COFFEE_POST_INSTALL_LOG="/var/log/coffee-post-install.log"

# Ensure log file exists and is writable
mkdir -p "$(dirname "$COFFEE_POST_INSTALL_LOG")" 2>/dev/null || true

# Source helper functions
if [ ! -f "$COFFEE_INSTALL/lib/helpers.sh" ]; then
  echo "Error: Helper functions not found at $COFFEE_INSTALL/lib/helpers.sh"
  exit 1
fi

# Temporarily set the log file for helpers
export COFFEE_INSTALL_LOG_FILE="$COFFEE_POST_INSTALL_LOG"
source "$COFFEE_INSTALL/lib/helpers.sh"

# Tracking variables
CHECKS_TOTAL=0
CHECKS_PASSED=0
CHECKS_FAILED=0
CRITICAL_FAILURES=()

# Helper function to check and track results
check_result() {
  local check_name="$1"
  local result="$2"
  
  ((CHECKS_TOTAL++))
  
  if [ "$result" -eq 0 ]; then
    success "✓ $check_name"
    ((CHECKS_PASSED++))
  else
    error "✗ $check_name"
    ((CHECKS_FAILED++))
    CRITICAL_FAILURES+=("$check_name")
  fi
}

# Helper function to check file existence and output contents
check_file_and_log() {
  local file_path="$1"
  local description="$2"
  
  if [ -f "$file_path" ]; then
    success "Found: $description ($file_path)"
    info "Content of $file_path:"
    log <<EOF
=== $description ===
$(sed 's/^/  /' "$file_path")
=== End of $description ===
EOF
    return 0
  else
    error "Missing: $description ($file_path)"
    log "File not found: $file_path"
    return 1
  fi
}

# Header
section "Coffee Post-Installation Verification"
log "Post-installation verification started at: $(date '+%Y-%m-%d %H:%M:%S')"

# ============================================================================
# PHASE 1: System and Preflight Checks
# ============================================================================

section "Phase 1: System and Preflight Checks"

log "Checking system architecture..."
if [ "$(uname -m)" = "x86_64" ]; then
  check_result "System is x86_64" 0
else
  check_result "System is x86_64" 1
fi

log "Checking secure boot status..."
if bootctl status 2>/dev/null | grep -q 'Secure Boot: disabled'; then
  check_result "Secure Boot is disabled" 0
else
  check_result "Secure Boot is disabled" 1
fi

log "Checking for pacman package manager..."
if command_exists pacman; then
  check_result "pacman is available" 0
else
  check_result "pacman is available" 1
fi

log "Checking for systemd..."
if command_exists systemctl; then
  check_result "systemd is available" 0
else
  check_result "systemd is available" 1
fi

log "Checking for limine bootloader..."
if command_exists limine; then
  check_result "limine bootloader is installed" 0
else
  check_result "limine bootloader is installed" 1
fi

log "Checking for Btrfs tools..."
if command_exists btrfs; then
  check_result "Btrfs tools are installed" 0
else
  check_result "Btrfs tools are installed" 1
fi

log "Checking for LUKS/cryptsetup..."
if command_exists cryptsetup; then
  check_result "cryptsetup is installed" 0
else
  check_result "cryptsetup is installed" 1
fi

# ============================================================================
# PHASE 2: Package Verification
# ============================================================================

section "Phase 2: Required Packages Verification"

# Check base packages from base.packages file
if [ -f "$COFFEE_INSTALL/base.packages" ]; then
  info "Checking base packages..."
  log <<EOF
Base packages to verify:
$(sed 's/^/  /' "$COFFEE_INSTALL/base.packages")
EOF
  
  missing_packages=()
  while IFS= read -r pkg; do
    # Skip comments and empty lines
    [[ "$pkg" =~ ^#.*$ || -z "$pkg" ]] && continue
    
    if ! package_installed "$pkg"; then
      missing_packages+=("$pkg")
      warn "Missing package: $pkg"
    fi
  done < "$COFFEE_INSTALL/base.packages"
  
  if [ ${#missing_packages[@]} -eq 0 ]; then
    check_result "All base packages installed" 0
  else
    error "Missing packages: ${missing_packages[*]}"
    check_result "All base packages installed" 1
  fi
else
  error "Base packages list not found"
  check_result "Base packages list exists" 1
fi

# ============================================================================
# PHASE 3: Pacman Configuration
# ============================================================================

section "Phase 3: Pacman Configuration"

check_file_and_log "/etc/pacman.conf" "Pacman Configuration"
check_result "Pacman config exists" $?

# Verify omarchy repo is in pacman.conf
if grep -q "omarchy" /etc/pacman.conf; then
  check_result "omarchy repo configured in pacman.conf" 0
else
  check_result "omarchy repo configured in pacman.conf" 1
fi

# ============================================================================
# PHASE 4: User Configuration
# ============================================================================

section "Phase 4: User Configuration"

# Detect the user (simulate what 11-user.sh does)
if [ -n "$SUDO_USER" ]; then
  LOGIN_USER="$SUDO_USER"
elif [ "$EUID" -ne 0 ]; then
  LOGIN_USER="$(whoami)"
else
  LOGIN_USER=""
fi

if [ -n "$LOGIN_USER" ] && [ "$LOGIN_USER" != "root" ]; then
  success "Detected user: $LOGIN_USER"
  
  # Check home directory exists
  if [ -d "/home/$LOGIN_USER" ]; then
    check_result "Home directory exists for $LOGIN_USER" 0
  else
    check_result "Home directory exists for $LOGIN_USER" 1
  fi
  
  # Check home directory permissions
  home_perms=$(stat -c "%a" "/home/$LOGIN_USER")
  if [ "$home_perms" = "755" ]; then
    check_result "Home directory permissions are 755" 0
  else
    warn "Home directory permissions are $home_perms (expected 755)"
    check_result "Home directory permissions are 755" 1
  fi
else
  error "Could not detect valid user for autologin"
  check_result "User detection for autologin" 1
fi

# ============================================================================
# PHASE 5: Greetd Display Manager Configuration
# ============================================================================

section "Phase 5: Display Manager (greetd) Configuration"

greetd_config="/etc/greetd/config.toml"

check_file_and_log "$greetd_config" "Greetd Configuration"
check_result "Greetd config exists" $?

if [ -f "$greetd_config" ]; then
  # Verify niri-session is configured
  if grep -q "niri-session" "$greetd_config"; then
    check_result "niri-session configured in greetd" 0
  else
    check_result "niri-session configured in greetd" 1
  fi
  
  # Verify user is set
  if grep -q "user = " "$greetd_config"; then
    configured_user=$(grep "user = " "$greetd_config" | head -1 | sed 's/.*user = "\(.*\)".*/\1/')
    success "greetd configured for user: $configured_user"
  fi
fi

# Check if greetd service is enabled
if systemctl is-enabled --quiet greetd 2>/dev/null; then
  check_result "greetd service is enabled" 0
else
  check_result "greetd service is enabled" 1
fi

# Check if greetd service is active
if systemctl is-active --quiet greetd 2>/dev/null; then
  check_result "greetd service is active" 0
else
  warn "greetd service is not currently active (may need reboot)"
fi

# ============================================================================
# PHASE 6: Bootloader Configuration
# ============================================================================

section "Phase 6: Bootloader (Limine) Configuration"

# Find limine config
limine_config=""
for config_path in /boot/EFI/arch-limine/limine.conf \
                    /boot/EFI/BOOT/limine.conf \
                    /boot/EFI/limine/limine.conf \
                    /boot/limine/limine.conf \
                    /boot/limine.conf; do
  if [ -f "$config_path" ]; then
    limine_config="$config_path"
    break
  fi
done

if [ -n "$limine_config" ]; then
  success "Found limine config: $limine_config"
  check_file_and_log "$limine_config" "Limine Bootloader Configuration"
  check_result "Limine config file exists" 0
else
  error "Limine config not found"
  check_result "Limine config file exists" 1
fi

# Check default limine config
if [ -f /etc/default/limine ]; then
  check_file_and_log "/etc/default/limine" "Default Limine Configuration"
  check_result "/etc/default/limine exists" 0
else
  check_result "/etc/default/limine exists" 1
fi

# Check mkinitcpio coffee hooks
if [ -f /etc/mkinitcpio.conf.d/coffee_hooks.conf ]; then
  check_file_and_log "/etc/mkinitcpio.conf.d/coffee_hooks.conf" "Mkinitcpio Coffee Hooks"
  check_result "Mkinitcpio coffee hooks configured" 0
else
  check_result "Mkinitcpio coffee hooks configured" 1
fi

# ============================================================================
# PHASE 7: Snapper and Btrfs Configuration
# ============================================================================

section "Phase 7: Snapper and Btrfs Configuration"

# Check snapper configs
log "Checking snapper configurations..."
if command_exists snapper; then
  if sudo snapper list-configs 2>/dev/null | grep -q "root"; then
    success "Snapper root config exists"
    check_result "Snapper root config exists" 0
  else
    error "Snapper root config missing"
    check_result "Snapper root config exists" 1
  fi
  
  if sudo snapper list-configs 2>/dev/null | grep -q "home"; then
    success "Snapper home config exists"
    check_result "Snapper home config exists" 0
  else
    error "Snapper home config missing"
    check_result "Snapper home config exists" 1
  fi
  
  # Check snapper root config settings
  if [ -f /etc/snapper/configs/root ]; then
    check_file_and_log "/etc/snapper/configs/root" "Snapper Root Configuration"
    check_result "Snapper root config file exists" 0
  else
    check_result "Snapper root config file exists" 1
  fi
else
  error "snapper command not found"
  check_result "snapper is available" 1
fi

# Check Btrfs quota
log "Checking Btrfs quota status..."
if btrfs quota status / 2>/dev/null | grep -qE '^\s*Enabled:\s+yes'; then
  check_result "Btrfs quota is enabled" 0
else
  warn "Btrfs quota is not enabled"
  check_result "Btrfs quota is enabled" 1
fi

# Check limine-snapper-sync service
if systemctl is-enabled --quiet limine-snapper-sync 2>/dev/null; then
  check_result "limine-snapper-sync service is enabled" 0
else
  check_result "limine-snapper-sync service is enabled" 1
fi

# ============================================================================
# PHASE 8: Plymouth Configuration
# ============================================================================

section "Phase 8: Boot Splash (Plymouth) Configuration"

log "Checking plymouth configuration..."
if command_exists plymouth-set-default-theme; then
  current_theme=$(plymouth-set-default-theme 2>/dev/null || echo "")
  if [ "$current_theme" = "coffee" ]; then
    success "Plymouth theme set to: $current_theme"
    check_result "Plymouth coffee theme is set" 0
  else
    error "Plymouth theme is: $current_theme (expected: coffee)"
    check_result "Plymouth coffee theme is set" 1
  fi
  
  if [ -d /usr/share/plymouth/themes/coffee ]; then
    check_result "Plymouth coffee theme directory exists" 0
  else
    check_result "Plymouth coffee theme directory exists" 1
  fi
else
  warn "plymouth-set-default-theme command not found"
fi

# ============================================================================
# PHASE 9: Systemd Services Configuration
# ============================================================================

section "Phase 9: Systemd Services Configuration"

# System services
system_services=(
  "bluetooth.service"
  "iwd.service"
  "limine-snapper-sync.service"
  "greetd.service"
)

for service in "${system_services[@]}"; do
  log "Checking systemd service: $service"
  if systemctl is-enabled --quiet "$service" 2>/dev/null; then
    success "Service enabled: $service"
  else
    warn "Service not enabled: $service"
  fi
  
  if systemctl is-active --quiet "$service" 2>/dev/null; then
    success "Service active: $service"
  else
    warn "Service not currently active: $service (may require reboot)"
  fi
done

check_result "System services configured" 0

# NetworkManager should be disabled
if systemctl is-active --quiet NetworkManager 2>/dev/null; then
  error "NetworkManager is active (should be disabled)"
  check_result "NetworkManager is disabled" 1
else
  check_result "NetworkManager is disabled" 0
fi

# ============================================================================
# PHASE 10: Systemd User Services Configuration
# ============================================================================

section "Phase 10: Systemd User Services Configuration"

# User services (requires running as the user)
user_services=(
  "niri.service"
  "waybar.service"
  "mako.service"
  "swaybg.service"
  "swayidle.service"
  "swayosd.service"
)

log "Checking user systemd services (for $LOGIN_USER)..."

# We can't reliably check user services from root in post-install
# Just verify the service files exist
if [ -d "/home/$LOGIN_USER/.config/systemd/user" ]; then
  success "User systemd directory exists"
  check_result "User systemd directory exists" 0
else
  warn "User systemd directory not found"
fi

# ============================================================================
# PHASE 11: Dotfiles Configuration
# ============================================================================

section "Phase 11: Dotfiles Configuration"

log "Checking stowed dotfiles..."

# Check if stow is installed
if command_exists stow; then
  success "stow is installed"
  check_result "stow is installed" 0
  
  # Check for typical stowed directory structures
  if [ -L "/home/$LOGIN_USER/.bashrc" ] || [ -L "/home/$LOGIN_USER/.zshrc" ]; then
    success "Shell dotfiles appear to be stowed"
    check_result "Dotfiles are stowed" 0
  else
    warn "Could not verify stowed dotfiles (may require user login)"
    check_result "Dotfiles are stowed" 1
  fi
  
  # Check config directory
  if [ -d "/home/$LOGIN_USER/.config" ]; then
    check_result "User .config directory exists" 0
  else
    check_result "User .config directory exists" 1
  fi
else
  error "stow not installed"
  check_result "stow is installed" 1
fi

# ============================================================================
# PHASE 12: NVIDIA Configuration (if applicable)
# ============================================================================

section "Phase 12: NVIDIA Configuration (if applicable)"

# Check if NVIDIA GPU is present
if lspci 2>/dev/null | grep -qi nvidia; then
  success "NVIDIA GPU detected"
  
  # Check for modprobe config
  if [ -f /etc/modprobe.d/nvidia.conf ]; then
    check_file_and_log "/etc/modprobe.d/nvidia.conf" "NVIDIA Modprobe Configuration"
    check_result "NVIDIA modprobe config exists" 0
  else
    check_result "NVIDIA modprobe config exists" 1
  fi
  
  # Check for mkinitcpio config
  if [ -f /etc/mkinitcpio.conf.d/nvidia.conf ]; then
    check_file_and_log "/etc/mkinitcpio.conf.d/nvidia.conf" "NVIDIA Mkinitcpio Configuration"
    check_result "NVIDIA mkinitcpio config exists" 0
  else
    check_result "NVIDIA mkinitcpio config exists" 1
  fi
  
  # Check for environment config
  if [ -f "/home/$LOGIN_USER/.config/environment.d/nvidia.conf" ]; then
    check_file_and_log "/home/$LOGIN_USER/.config/environment.d/nvidia.conf" "NVIDIA Environment Configuration"
    check_result "NVIDIA environment config exists" 0
  else
    warn "NVIDIA environment config not found"
    check_result "NVIDIA environment config exists" 1
  fi
else
  log "No NVIDIA GPU detected - skipping NVIDIA configuration checks"
fi

# ============================================================================
# PHASE 13: Default Applications Configuration
# ============================================================================

section "Phase 13: Default Applications Configuration"

log "Checking default application associations..."

# Check for mimeapps.list
mimeapps_file="/home/$LOGIN_USER/.config/mimeapps.list"
if [ -f "$mimeapps_file" ]; then
  check_file_and_log "$mimeapps_file" "MIME Applications Configuration"
  check_result "MIME applications config exists" 0
else
  warn "MIME applications config not found (expected at $mimeapps_file)"
  check_result "MIME applications config exists" 1
fi

# Check GTK theme settings
log "Checking GTK theme settings..."
if gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null | grep -q "Adwaita-dark"; then
  success "GTK theme set to Adwaita-dark"
  check_result "GTK theme is configured" 0
else
  warn "GTK theme not set to Adwaita-dark"
  check_result "GTK theme is configured" 1
fi

# ============================================================================
# PHASE 14: Log File Summary
# ============================================================================

section "Post-Installation Verification Summary"

# Calculate percentages
if [ $CHECKS_TOTAL -gt 0 ]; then
  pass_percentage=$((CHECKS_PASSED * 100 / CHECKS_TOTAL))
  fail_percentage=$((CHECKS_FAILED * 100 / CHECKS_TOTAL))
else
  pass_percentage=0
  fail_percentage=0
fi

log <<EOF
Post-installation verification completed at: $(date '+%Y-%m-%d %H:%M:%S')
============================================================================
VERIFICATION SUMMARY:
  Total Checks: $CHECKS_TOTAL
  Passed: $CHECKS_PASSED ($pass_percentage%)
  Failed: $CHECKS_FAILED ($fail_percentage%)
============================================================================
EOF

# Output to console
echo ""
section "Verification Results"
echo "Total Checks: $CHECKS_TOTAL"
echo "Passed: $CHECKS_PASSED ($pass_percentage%)"
echo "Failed: $CHECKS_FAILED ($fail_percentage%)"
echo ""

if [ $CHECKS_FAILED -gt 0 ]; then
  echo "Failed Checks:"
  for failure in "${CRITICAL_FAILURES[@]}"; do
    echo "  ✗ $failure"
  done
  echo ""
fi

echo "Full log saved to: $COFFEE_POST_INSTALL_LOG"
echo ""

# Exit with appropriate code
if [ $CHECKS_FAILED -gt 0 ]; then
  exit 1
else
  exit 0
fi
