#!/bin/bash

# Exit immediately if a command exists with a non-zero status
set -eEo pipefail

source "$COFFEE_INSTALL/post-install/mime.sh"
source "$COFFEE_INSTALL/post-install/systemd-user.sh"
