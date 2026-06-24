#!/usr/bin/env bats
# Integration tests for 03-post.sh.

source "${BATS_TEST_DIRNAME}/test_helper.bash"

setup() { setup_sandbox; }
teardown() { teardown_sandbox; }

@test "compact: reloads php-fpm and runs deploy:after" {
  RELEASE="$SANDBOX/rel"
  mkdir -p "$RELEASE"
  make_mock composer <<'EOF'
#!/bin/bash
echo "deploy:after ran"
EOF
  run env RELEASE="$RELEASE" RELOAD_PHP_FPM="touch '$SANDBOX/fpm.flag'" \
    DEPLOY_OUTPUT=compact bash "$PROJECT_ROOT/03-post.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Reloading PHP-FPM"* ]]
  [[ "$output" == *"Optimizing Activation"* ]]
  [ -f "$SANDBOX/fpm.flag" ]
}

@test "aborts when RELOAD_PHP_FPM is missing" {
  RELEASE="$SANDBOX/rel"
  mkdir -p "$RELEASE"
  run env -u RELOAD_PHP_FPM RELEASE="$RELEASE" bash "$PROJECT_ROOT/03-post.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"required variable 'RELOAD_PHP_FPM' is not set"* ]]
}
