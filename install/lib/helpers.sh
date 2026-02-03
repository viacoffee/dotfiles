#!/usr/bin/env bash

install_packages_from_file() {
  local package_file="$1"
  mapfile -t packages < <(grep -v '^#' "$package_file" | grep -v '^$')
  sudo pacman -S --needed --noconfirm "${packages[@]}"
}
