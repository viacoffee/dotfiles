#!/bin/bash
count=$(makoctl list 2>/dev/null | grep -c '^Notification ') 

if [ "$count" -gt 0 ]; then
  echo '{"text": "󰅾", "tooltip": "View notifications", "class": "active"}'
else
  echo '{"text": ""}'
fi
