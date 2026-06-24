#!/usr/bin/env bats
# Integration tests for 01-pre.sh.

source "${BATS_TEST_DIRNAME}/test_helper.bash"

setup() { setup_sandbox; }
teardown() { teardown_sandbox; }

prepare() {
  RELEASE="$SANDBOX/rel"
  mkdir -p "$RELEASE"
  export RELEASE REPOSITORY_USER=me REPOSITORY_NAME=app COMMIT_HASH=abc \
    GITHUB_TOKEN=tok LARAVEL_ENV_ENCRYPTION_KEY=key
}

@test "initializes a git repo with the correct origin URL" {
  prepare
  run bash "$PROJECT_ROOT/01-pre.sh"
  [ "$status" -eq 0 ]
  [ -d "$RELEASE/.git" ]
  run git -C "$RELEASE" remote get-url origin
  [[ "$output" == *"github.com/me/app.git"* ]]
}

@test "is idempotent when run twice on the same release" {
  prepare
  run bash "$PROJECT_ROOT/01-pre.sh"
  [ "$status" -eq 0 ]
  run bash "$PROJECT_ROOT/01-pre.sh"
  [ "$status" -eq 0 ]
}

@test "aborts when a required variable is missing" {
  prepare
  run env -u GITHUB_TOKEN bash "$PROJECT_ROOT/01-pre.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"required variable 'GITHUB_TOKEN' is not set"* ]]
}
