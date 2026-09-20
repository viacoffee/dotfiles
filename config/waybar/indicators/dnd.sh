#!/bin/bash

if [ "$(kara notify mute status)" = "true" ]; then
  echo '{"text": "󰜺", "tooltip": "Disable dnd", "class": "active"}'
else
  echo '{"text": ""}'
fi
