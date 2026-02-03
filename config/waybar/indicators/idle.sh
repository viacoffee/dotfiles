#!/bin/bash

if ! pgrep -f hypridle >/dev/null; then
  echo '{"text": "", "tooltip": "Enable idle lock", "class": "active"}'
else
  echo '{"text": ""}'
fi
