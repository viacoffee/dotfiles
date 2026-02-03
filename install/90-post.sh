#!/usr/bin/env bash
set -euo pipefail

echo "Install/update Mise"
if ! command -v mise >/dev/null; then
  curl -fsSL https://mise.run | sh
else
  mise self-update || true
fi

# Update tldr definitions
tldr --update || true
