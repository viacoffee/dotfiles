#!/bin/bash

# Create zsh cache
log "Creating zsh cache directory..."
mkdir -p ~/.cache/zsh

# Set shell
log "Changing default shell..."
chsh -s /bin/zsh
