#!/bin/bash

# Bluetooth
if ! systemctl is-enabled --quiet bluetooth.service && ! systemctl is-active --quiet bluetooth.service; then
  run_logged "Enable bluetooth service" \
    "sudo systemctl enable bluetooth.service"
fi

# Wifi
if systemctl is-active --quiet NetworkManager; then
  run_logged "Disable NetworkManager service" \
    "sudo systemctl disable NetworkManager"
fi

if ! systemctl is-active --quiet iwd && ! systemctl is-active --quiet NetworkManager; then
  run_logged "Enable iwd service" \
    "sudo systemctl enable iwd.service"
fi

# Snapper-sync
if ! systemctl is-active --quiet limine-snapper-sync; then
  run_logged "Enable limine-snapper-sync service" \
    "sudo systemctl enable limine-snapper-sync.service"
fi

# Greetd
if ! systemctl is-enabled --quiet greetd.service; then
  run_logged "Enable greetd service" \
    "sudo systemctl enable greetd.service"
fi

# Power profile daemon
if ! systemctl is-enabled --quiet power-profiles-daemon; then
  run_logged "Enable power-profiles-daemon" \
    "sudo systemctl enable power-profiles-daemon"
fi

# Faster shutdown
# Ensure directory exists before copying
sudo mkdir -p "/etc/systemd/system.conf.d"
sudo cp "$COFFEE_INSTALL_DEFAULTS_PATH/systemd/faster-shutdown.conf" /etc/systemd/system.conf.d/10-faster-shutdown.conf

# Ensure .local/bin gets added to the encironment path
mkdir -p "$HOME/.config/environment.d"
cat > "$HOME/.config/environment.d/10-path.conf" <<'EOF'
PATH=$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin
EOF

run_logged "Reloading daemon" \
  "sudo systemctl daemon-reload"
