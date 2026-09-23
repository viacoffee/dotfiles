#!/bin/bash

build_project() (
  local definition=$1
  local build_dir source_dir installed_revision checkout_revision state_file state_tmp binary install_dir
  local -a binaries=()

  # shellcheck disable=SC1090 # project definitions are discovered by 21-builds.sh
  source "$definition"

  : "${BUILD_NAME:?BUILD_NAME is required in $definition}"
  : "${BUILD_SOURCE:?BUILD_SOURCE is required in $definition}"
  : "${BUILD_REVISION:?BUILD_REVISION is required in $definition}"
  : "${BUILD_KIND:?BUILD_KIND is required in $definition}"
  : "${BUILD_BINARY:?BUILD_BINARY is required in $definition}"
  install_dir=${BUILD_INSTALL_DIR:-$HOME/.local/bin}
  if declare -p BUILD_BINARIES >/dev/null 2>&1; then
    binaries=("${BUILD_BINARIES[@]}")
  else
    binaries=("$BUILD_BINARY")
  fi
  if [[ ! " ${binaries[*]} " == *" $BUILD_BINARY "* ]]; then
    binaries=("$BUILD_BINARY" "${binaries[@]}")
  fi

  if [[ ! $BUILD_NAME =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]]; then
    error "Invalid build name: $BUILD_NAME"
    return 1
  fi

  state_file="${DOTFILES_BUILD_STATE_DIR:-$HOME/.local/state/dotfiles/builds}/$BUILD_NAME.revision"
  if [[ -f $state_file ]]; then
    installed_revision=$(<"$state_file")
  else
    installed_revision=
  fi

  if [[ $installed_revision == "$BUILD_REVISION" ]]; then
    local binaries_current=1
    for binary in "${binaries[@]}"; do
      if [[ ! -x "$install_dir/$binary" || ( $BUILD_KIND == go && -L "$install_dir/$binary" ) ]]; then
        binaries_current=0
      fi
    done
    if ((binaries_current)); then
      log "Build is current: $BUILD_NAME ($BUILD_REVISION)"
      return 0
    fi
  fi

  case $BUILD_KIND in
    cargo)
      command_exists git || { error "Build dependency is missing for $BUILD_NAME: git"; return 1; }
      command_exists cargo || { error "Build dependency is missing for $BUILD_NAME: cargo"; return 1; }
      ;;
    go)
      command_exists go || { error "Build dependency is missing for $BUILD_NAME: go"; return 1; }
      [[ -d $BUILD_SOURCE ]] || { error "Local Go source directory not found for $BUILD_NAME: $BUILD_SOURCE"; return 1; }
      ;;
    *)
      error "Unsupported build kind for $BUILD_NAME: $BUILD_KIND"
      return 1
      ;;
  esac

  mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/builds"
  build_dir=$(mktemp -d "${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/builds/$BUILD_NAME.XXXXXX")
  trap 'rm -rf -- "$build_dir"' EXIT
  source_dir="$build_dir/source"

  if [[ $BUILD_KIND == cargo ]]; then
    run_logged "Cloning $BUILD_NAME source" git clone --no-checkout "$BUILD_SOURCE" "$source_dir"
    run_logged "Checking out $BUILD_NAME revision" \
      git -C "$source_dir" checkout --detach "$BUILD_REVISION"
    checkout_revision=$(git -C "$source_dir" rev-parse HEAD)
    if [[ $checkout_revision != "$BUILD_REVISION" ]]; then
      error "Checked out revision does not match $BUILD_NAME revision"
      return 1
    fi
  else
    source_dir=$BUILD_SOURCE
  fi

  case $BUILD_KIND in
    cargo)
      (
        cd "$source_dir" || exit 1
        run_logged "Building $BUILD_NAME" \
          cargo install --path . --locked --root "$HOME/.local" --force
      )
      ;;
    go)
      mkdir -p "$build_dir/bin"
      for binary in "${binaries[@]}"; do
        run_logged "Building $BUILD_NAME ($binary)" \
          go -C "$source_dir" build -trimpath -ldflags='-s -w' -o "$build_dir/bin/$binary" "./cmd/$binary"
      done
      ;;
  esac

  if [[ $BUILD_KIND == go ]]; then
    for binary in "${binaries[@]}"; do
      if [[ ! -x $build_dir/bin/$binary ]]; then
        error "Build did not produce expected executable: $build_dir/bin/$binary"
        return 1
      fi
      install -Dm755 "$build_dir/bin/$binary" "$install_dir/$binary"
    done
  else
    for binary in "${binaries[@]}"; do
      if [[ ! -x $install_dir/$binary ]]; then
        error "Build did not install expected executable: $install_dir/$binary"
        return 1
      fi
    done
  fi

  mkdir -p "${state_file%/*}"
  state_tmp=$(mktemp "${state_file%/*}/.$BUILD_NAME.XXXXXX")
  printf '%s\n' "$BUILD_REVISION" > "$state_tmp"
  mv -f -- "$state_tmp" "$state_file"
  success "Build installed: $BUILD_NAME ($BUILD_REVISION)"
)
