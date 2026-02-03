#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$INSTALL_DIR/lib/helpers.sh"

# Ensure mako daemon is running
systemctl --user restart mako || true
