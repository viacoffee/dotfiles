#!/bin/bash

step "Configuring firewall defaults"

# Allow nothing in, everything out
run_logged "Denying unsolicited incoming traffic" sudo ufw default deny incoming
run_logged "Allowing outgoing traffic" sudo ufw default allow outgoing

# Allow ports for LocalSend
run_logged "Allowing LocalSend UDP traffic" sudo ufw allow 53317/udp
run_logged "Allowing LocalSend TCP traffic" sudo ufw allow 53317/tcp

# Keep host-side automation reachable only on explicitly marked test VMs.
if [[ -f /etc/dotfiles-test-vm && -n ${SSH_CONNECTION:-} ]]; then
  ssh_client_ip=${SSH_CONNECTION%% *}
  run_logged "Allowing test VM SSH traffic" \
    sudo ufw allow from "$ssh_client_ip" to any port 22 proto tcp \
      comment 'allow-dotfiles-test-host-ssh'
fi

# Turn on the firewall
run_logged "Enabling UFW" sudo ufw --force enable

# Enable UFW systemd service to start on boot
run_logged "Enabling the UFW system service" sudo systemctl enable ufw

success "Firewall configured and enabled"
