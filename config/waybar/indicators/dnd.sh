#!/bin/bash

if [ "$(makoctl mode)" == "dnd" ]; then
  echo '{"text": "󰜺", "tooltip": "Disable dnd", "class": "active"}'
else
  echo '{"text": ""}'
fi
