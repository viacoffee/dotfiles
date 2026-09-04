#!/usr/bin/env bats

setup() {
  repo_root=$(cd "$BATS_TEST_DIRNAME/.." && pwd)
  dot_dev="$repo_root/local/bin/dot-dev"
  package_dir=$(mktemp -d)
  export DOT_DEV_PACKAGE_DIR="$package_dir"
  export TEST_LOG="$package_dir/actions"

  write_package docker installed 'Docker details'
  write_package mise 'not installed' 'Mise details'
}

teardown() {
  rm -rf "$package_dir"
}

write_package() {
  local name=$1 state=$2 details=$3

  cat > "$package_dir/$name" <<EOF
case \${1:-status} in
  summary) printf '%s\\n' '$state' ;;
  status) printf '%s\\n' '$details' ;;
  install|remove) printf '%s %s\\n' "\$1" '$name' >> "\$TEST_LOG" ;;
  *) exit 2 ;;
esac
EOF
}

@test "dot-dev status lists package summaries" {
  run "$dot_dev" status

  [ "$status" -eq 0 ]
  [ "$output" = $'Available development environments:\n  docker           installed\n  mise             not installed' ]
}

@test "dot-dev defaults to aggregate status" {
  run "$dot_dev"

  [ "$status" -eq 0 ]
  [[ "$output" == *'docker           installed'* ]]
}

@test "dot-dev status package prints detailed status" {
  run "$dot_dev" status mise

  [ "$status" -eq 0 ]
  [ "$output" = 'Mise details' ]
}

@test "dot-dev dispatches lifecycle commands" {
  run "$dot_dev" install docker
  [ "$status" -eq 0 ]

  run "$dot_dev" remove mise
  [ "$status" -eq 0 ]
  [ "$(<"$TEST_LOG")" = $'install docker\nremove mise' ]
}

@test "dot-dev rejects unknown packages and invalid arguments" {
  run "$dot_dev" install unknown
  [ "$status" -eq 2 ]
  [[ "$output" == *'Unknown development environment: unknown'* ]]

  run "$dot_dev" status docker extra
  [ "$status" -eq 2 ]
}

@test "dot-dev help and missing package scripts behave as documented" {
  run "$dot_dev" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *'dot-dev install <package>'* ]]

  rm "$package_dir/mise"
  run "$dot_dev" status mise
  [ "$status" -eq 2 ]
}
