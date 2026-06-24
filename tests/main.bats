#!/usr/bin/env bats
# Integration tests for 02-main.sh with mocked wget/composer.

source "${BATS_TEST_DIRNAME}/test_helper.bash"

setup() { setup_sandbox; }
teardown() { teardown_sandbox; }

# Build a realistic release dir and a fake source tarball, and mock wget to serve
# it. Exports the env vars 02-main.sh needs (composer is mocked per test).
prepare_release() {
  RELEASE="$SANDBOX/site-deploy/site/REL"
  mkdir -p "$RELEASE"
  mkdir -p "$SANDBOX/src/repo/storage"
  echo "marker" > "$SANDBOX/src/repo/marker.txt"
  ( cd "$SANDBOX/src" && tar -czf "$SANDBOX/src.tgz" repo )
  make_mock wget <<EOF
#!/bin/bash
cat "$SANDBOX/src.tgz"
EOF
  export RELEASE REPOSITORY_USER=me REPOSITORY_NAME=app COMMIT_HASH=abc GITHUB_TOKEN=tok
}

@test "compact happy path: fetch, link storage, install, build" {
  prepare_release
  make_mock composer <<'EOF'
#!/bin/bash
case "$1" in
  install) echo "Package operations: 301 installs, 0 updates, 0 removals" ;;
  deploy:before) echo "transforming..."; echo "✓ built in 5.80s" ;;
esac
EOF
  run env DEPLOY_OUTPUT=compact bash "$PROJECT_ROOT/02-main.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"✓  (301 installs)"* ]]
  [[ "$output" == *"✓  (built in 5.80s)"* ]]
  [[ "$output" == *"Activating App!"* ]]
  [ -f "$RELEASE/marker.txt" ]
  # The shared storage dir is moved out of the release and linked back in.
  [ -d "$SANDBOX/site-deploy/storage" ]
  if supports_symlinks; then
    [ -L "$RELEASE/storage" ]
  else
    [ -e "$RELEASE/storage" ]
  fi
}

@test "honors SITE_COMPOSER so composer runs on the site's PHP binary" {
  prepare_release
  make_mock composer <<'EOF'
#!/bin/bash
case "$1" in
  install) echo "Package operations: 5 installs" ;;
esac
EOF
  make_mock php8.2 <<EOF
#!/bin/bash
echo used >> "$SANDBOX/php.log"
exec "\$@"
EOF
  run env DEPLOY_OUTPUT=compact SITE_COMPOSER="php8.2 $MOCK_BIN/composer" \
    bash "$PROJECT_ROOT/02-main.sh"
  [ "$status" -eq 0 ]
  [ -f "$SANDBOX/php.log" ]
}

@test "aborts before touching the filesystem when RELEASE is unset" {
  run env -u RELEASE DEPLOY_OUTPUT=compact bash "$PROJECT_ROOT/02-main.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"required variable 'RELEASE' is not set"* ]]
}

@test "compact: a failing composer install dumps output and aborts" {
  prepare_release
  make_mock composer <<'EOF'
#!/bin/bash
if [ "$1" = "install" ]; then echo "could not be resolved"; exit 2; fi
EOF
  run env DEPLOY_OUTPUT=compact bash "$PROJECT_ROOT/02-main.sh"
  [ "$status" -eq 2 ]
  [[ "$output" == *"✗  (exit 2)"* ]]
  [[ "$output" == *"could not be resolved"* ]]
}
