#!/bin/bash

if rfkill list wifi | grep -q "Soft blocked: yes" && rfkill list bluetooth | grep -q "Soft blocked: yes"; then
  echo '{"text": "󰀝", "tooltip": "Airplane mode on", "class": "active"}'
else
  echo '{"text": ""}'
fi
