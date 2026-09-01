#!/bin/bash

info "Configuring UFW: deny unsolicited incoming traffic and allow outgoing traffic..."

# Allow nothing in, everything out
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow ports for LocalSend
sudo ufw allow 53317/udp
sudo ufw allow 53317/tcp

# Keep host-side automation reachable only on explicitly marked test VMs.
if [[ -f /etc/dotfiles-test-vm && -n ${SSH_CONNECTION:-} ]]; then
  ssh_client_ip=${SSH_CONNECTION%% *}
  sudo ufw allow from "$ssh_client_ip" to any port 22 proto tcp \
    comment 'allow-dotfiles-test-host-ssh'
fi

# Turn on the firewall
sudo ufw --force enable

# Enable UFW systemd service to start on boot
sudo systemctl enable ufw

success "Firewall configured and enabled"
