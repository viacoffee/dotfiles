#!/usr/bin/env bash
set -euo pipefail

# Update tldr definitions
tldr --update || true

# Safety: enable warland for firefox
echo 'export MOZ_ENABLE_WAYLAND=1' > ~/.config/environment.d/firefox.conf
