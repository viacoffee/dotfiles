#!/usr/bin/env bash
set -euo pipefail

command -v pacman > /dev/null || {
  echo "Imagine not being on arch"
  exit 1
}

sudo -v
