#!/bin/bash

if kara notify mute status | jq -e '.data.value == true' >/dev/null; then
  echo '{"text": "󰜺", "tooltip": "Disable dnd", "class": "active"}'
else
  echo '{"text": ""}'
fi
