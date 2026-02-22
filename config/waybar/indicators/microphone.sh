#!/bin/bash

if lsof /dev/snd/* 2>/dev/null | grep -q .; then
  echo '{"text": "󰍬", "tooltip": "Microphone active", "class": "active"}'
else
  echo '{"text": ""}'
fi
