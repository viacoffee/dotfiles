#!/bin/bash

if pgrep -x postgres >/dev/null; then
    echo '{"text": "", "tooltip": "Kill postgresql", "class": "active"}'
else
    echo '{"text": ""}'
fi
