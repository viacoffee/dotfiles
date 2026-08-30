#!/bin/bash

log "Updating system and installing required packages..."

PACMAN_CONF=${PACMAN_CONF:-/etc/pacman.conf}
PACMAN_ORIGINAL_BACKUP=${PACMAN_ORIGINAL_BACKUP:-$PACMAN_CONF.dotfiles-original}
PACMAN_ORIGINAL_CHECKSUM=${PACMAN_ORIGINAL_CHECKSUM:-$PACMAN_ORIGINAL_BACKUP.sha256}
PACMAN_REPOSITORY_FRAGMENT=${PACMAN_REPOSITORY_FRAGMENT:-/etc/pacman.d/dotfiles-repositories.conf}
REPOSITORY_FRAGMENT_SOURCE="$DOTFILES_INSTALL_DEFAULTS_PATH/pacman/dotfiles-repositories.conf"

if [[ ! -f $DOTFILES_INSTALL/packages ]]; then
  error "Package list not found: $DOTFILES_INSTALL/packages"
  return 1
fi
if [[ ! -f $REPOSITORY_FRAGMENT_SOURCE ]]; then
  error "Repository fragment not found: $REPOSITORY_FRAGMENT_SOURCE"
  return 1
fi

declare -a required_packages=()
mapfile -t required_packages < <(grep -Ev '^(#|[[:space:]]*$)' "$DOTFILES_INSTALL/packages")
if ((${#required_packages[@]} == 0)); then
  error "Package list is empty: $DOTFILES_INSTALL/packages"
  return 1
fi

preserve_original_pacman_configuration() {
  local saved_hash current_hash

  if [[ -e $PACMAN_ORIGINAL_BACKUP || -e $PACMAN_ORIGINAL_CHECKSUM ]]; then
    if [[ ! -f $PACMAN_ORIGINAL_BACKUP || ! -f $PACMAN_ORIGINAL_CHECKSUM ]]; then
      error "Pacman recovery files are incomplete"
      return 1
    fi
    saved_hash=$(sudo cat "$PACMAN_ORIGINAL_CHECKSUM" | tr -d '[:space:]')
    current_hash=$(sudo sha256sum "$PACMAN_ORIGINAL_BACKUP" | awk '{print $1}')
    if [[ -z $saved_hash || $saved_hash != "$current_hash" ]]; then
      error "Pacman configuration backup checksum does not match"
      return 1
    fi
    success "Original pacman configuration backup is intact"
    return
  fi

  run_logged "Preserving original pacman configuration" \
    sudo cp --preserve=mode,timestamps "$PACMAN_CONF" "$PACMAN_ORIGINAL_BACKUP"
  saved_hash=$(sudo sha256sum "$PACMAN_ORIGINAL_BACKUP" | awk '{print $1}')
  printf '%s\n' "$saved_hash" | sudo tee "$PACMAN_ORIGINAL_CHECKSUM" >/dev/null
  success "Original pacman configuration saved: $PACMAN_ORIGINAL_BACKUP"
}

write_managed_pacman_configuration() {
  local staged_conf multilib_active=0

  if pacman-conf --repo-list | grep -qx multilib; then
    multilib_active=1
  fi

  staged_conf=$(mktemp)
  awk \
    -v activate_multilib="$((1 - multilib_active))" \
    -v managed_fragment="$PACMAN_REPOSITORY_FRAGMENT" '
      function emit(line) {
        while (pending_blanks > 0) {
          print ""
          pending_blanks--
        }
        print line
      }

      BEGIN {
        skip_omarchy = 0
        waiting_for_multilib_include = 0
        pending_blanks = 0
      }

      /^[[:space:]]*#[[:space:]]*Dotfiles-managed third-party repositories[[:space:]]*$/ {
        next
      }

      $0 ~ "^[[:space:]]*Include[[:space:]]*=[[:space:]]*" managed_fragment "[[:space:]]*$" {
        next
      }

      /^[[:space:]]*\[omarchy\][[:space:]]*$/ {
        skip_omarchy = 1
        next
      }

      skip_omarchy && /^[[:space:]]*\[[^]]+\][[:space:]]*$/ {
        skip_omarchy = 0
      }

      skip_omarchy { next }

      activate_multilib && /^[[:space:]]*#[[:space:]]*\[multilib\][[:space:]]*$/ {
        emit("[multilib]")
        waiting_for_multilib_include = 1
        next
      }

      waiting_for_multilib_include && /^[[:space:]]*#[[:space:]]*Include[[:space:]]*=[[:space:]]*\/etc\/pacman\.d\/mirrorlist[[:space:]]*$/ {
        emit("Include = /etc/pacman.d/mirrorlist")
        waiting_for_multilib_include = 0
        next
      }

      /^[[:space:]]*$/ {
        pending_blanks++
        next
      }

      { emit($0) }

      END {
        print ""
        print "# Dotfiles-managed third-party repositories"
        print "Include = " managed_fragment
      }
    ' "$PACMAN_CONF" > "$staged_conf"

  sudo install -Dm644 "$REPOSITORY_FRAGMENT_SOURCE" "$PACMAN_REPOSITORY_FRAGMENT"

  if ! pacman-conf --config="$staged_conf" --repo-list >/dev/null; then
    rm -f "$staged_conf"
    error "Staged pacman configuration is invalid"
    return 1
  fi

  run_logged "Installing managed pacman configuration" \
    sudo cp "$staged_conf" "$PACMAN_CONF"
  rm -f "$staged_conf"
}

validate_pacman_configuration() {
  local repository count
  local repositories

  repositories=$(pacman-conf --repo-list) || {
    error "Unable to read effective pacman configuration"
    return 1
  }

  for repository in core extra multilib omarchy; do
    count=$(grep -cx "$repository" <<< "$repositories" || true)
    if ((count != 1)); then
      error "Repository must be configured exactly once: $repository (found $count)"
      return 1
    fi
  done

  if [[ $(pacman-conf --repo omarchy Server) != "https://pkgs.omarchy.org/stable/$(uname -m)" ]]; then
    error "Omarchy repository server does not match the managed configuration"
    return 1
  fi

  local omarchy_siglevel
  omarchy_siglevel=$(pacman-conf --repo omarchy SigLevel)
  for policy in PackageOptional PackageTrustAll DatabaseOptional DatabaseTrustAll; do
    if ! grep -qx "$policy" <<< "$omarchy_siglevel"; then
      error "Omarchy repository signature policy is missing: $policy"
      return 1
    fi
  done

  success "Pacman repositories and signature policy validated"
}

preserve_original_pacman_configuration
write_managed_pacman_configuration
validate_pacman_configuration

# Refresh repository databases so newly configured repository packages can be
# resolved before any system upgrade begins.
run_logged "Synchronizing package databases" sudo pacman -Sy --noconfirm
validate_package_resolution "${required_packages[@]}"

run_logged "Updating system" sudo pacman -Syu --noconfirm
install_missing_packages "${required_packages[@]}"
