#!/bin/bash

if pw-dump | grep -q '"media.class".*"Stream/Output/Video"'; then
  echo '{"text": "󰐯", "tooltip": "Screen sharing active", "class": "active"}'
else
  echo '{"text": ""}'
fi
