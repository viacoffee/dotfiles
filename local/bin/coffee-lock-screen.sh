#!/usr/bin/env bash
set -euo pipefail

LOCK_CMD="swaylock \
  --screenshots \
  --clock \
  --indicator \
  --effect-blur 7x5 \
  --ring-color 3b4252 \
  --key-hl-color 88c0d0 \
  --inside-color 2e3440cc"

exec $LOCK_CMD
