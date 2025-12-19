#!/bin/bash

# Helper functions to remove some of the pre-installed packages/apps/webapps
#
# Based on https://github.com/maxart/omarchy-cleaner
APPS=(
    "obsidian"
    "xournalpp"
)
WEBAPPS=(
    "HEY"
    "Basecamp"
    "WhatsApp"
    "Google Photos"
    "Google Contacts"
    "Google Messages"
    "YouTube"
    "GitHub"
    "X"
    "Figma"
    "Discord"
    "Zoom"
)

# Function to check if webapp is installed
is_webapp_installed() {
    local webapp="$1"
    # Check if .desktop file exists for the webapp
    local desktop_file="$HOME/.local/share/applications/$webapp.desktop"
    [[ -f "$desktop_file" ]]
    return $?
}

# Function to check if package is installed
is_package_installed() {
    local package="$1"
    pacman -Qi "$package" &>/dev/null
    return $?
}

# Function to remove webapps
remove_webapps() {
    for webapp in "${WEBAPPS[@]}"; do
        if is_webapp_installed "$webapp"; then
            if gum spin --spinner dot --title "Removing $webapp..." -- bash -c "omarchy-webapp-remove '$webapp' >/dev/null 2>&1"; then
                success "removed: $webapp"
            else
                error "deletion of $webapp failed"
            fi
        fi
    done
}

# Function to remove packages
remove_packages() {
    for pkg in "${APPS[@]}"; do
        if is_package_installed "$pkg"; then
            if gum spin --spinner dot --title "Removing $pkg..." -- bash -c "sudo pacman -Rns --noconfirm '$pkg' 2>/dev/null"; then
                success "removed: $pkd"
            else
                error "deletion of $pkg failed"
            fi
        fi
    done
}

# Function to remove both webapps and packages
remove_all() {
    remove_webapps
    remove_packages
}
