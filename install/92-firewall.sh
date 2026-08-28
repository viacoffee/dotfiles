#!/bin/bash

info "Configuring UFW: deny unsolicited incoming traffic and allow outgoing traffic..."

# Allow nothing in, everything out
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow ports for LocalSend
sudo ufw allow 53317/udp
sudo ufw allow 53317/tcp

# Allow Docker containers to use DNS on host
sudo ufw allow in proto udp from 172.16.0.0/12 to 172.17.0.1 port 53 comment 'allow-docker-dns'

# Turn on the firewall
sudo ufw --force enable

# Enable UFW systemd service to start on boot
sudo systemctl enable ufw

# Turn on Docker protections
if command_exists ufw-docker; then
  info "Enabling Docker firewall protections..."
  sudo ufw-docker install
  sudo ufw reload
else
  warn "ufw-docker not found; Docker firewall protections were skipped"
fi

success "Firewall configured and enabled"
