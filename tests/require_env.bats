#!/usr/bin/env bats
# Unit tests for the require_env() helper (loaded from 02-main.sh).

source "${BATS_TEST_DIRNAME}/test_helper.bash"

setup() { setup_sandbox; }
teardown() { teardown_sandbox; }

@test "aborts with exit 1 and names a missing variable" {
  run_sourced full "$PROJECT_ROOT/02-main.sh" <<'EOF'
require_env DEFINITELY_MISSING_VAR
echo "SHOULD NOT RUN"
EOF
  [ "$status" -eq 1 ]
  [[ "$output" == *"required variable 'DEFINITELY_MISSING_VAR' is not set"* ]]
  [[ "$output" != *"SHOULD NOT RUN"* ]]
}

@test "treats an empty variable as missing" {
  run_sourced full "$PROJECT_ROOT/02-main.sh" <<'EOF'
export EMPTY_VAR=""
require_env EMPTY_VAR
EOF
  [ "$status" -eq 1 ]
  [[ "$output" == *"required variable 'EMPTY_VAR' is not set"* ]]
}

@test "passes when every named variable is set" {
  run_sourced full "$PROJECT_ROOT/02-main.sh" <<'EOF'
export A=1 B=2
require_env A B
echo "passed"
EOF
  [ "$status" -eq 0 ]
  [[ "$output" == *"passed"* ]]
}
