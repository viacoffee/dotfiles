#!/usr/bin/env bash
set -euo pipefail

if ! command -v mise >/dev/null; then
  curl -fsSL https://mise.run | sh
else
  mise self-update || true
fi
