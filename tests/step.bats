#!/usr/bin/env bats
# Unit tests for the step() helper (loaded from 02-main.sh).

source "${BATS_TEST_DIRNAME}/test_helper.bash"

setup() { setup_sandbox; }
teardown() { teardown_sandbox; }

@test "compact: success prints the --summary match next to the check" {
  run_sourced compact "$PROJECT_ROOT/02-main.sh" <<'EOF'
fake() { echo "Package operations: 301 installs, 0 updates, 0 removals"; }
step "Composer" --summary '[0-9]+ installs?' fake
EOF
  [ "$status" -eq 0 ]
  [[ "$output" == *"✓  (301 installs)"* ]]
}

@test "compact: success without --summary prints a bare check and hides output" {
  run_sourced compact "$PROJECT_ROOT/02-main.sh" <<'EOF'
fake() { echo "secret noise"; }
step "Step" fake
EOF
  [ "$status" -eq 0 ]
  [[ "$output" == *"✓"* ]]
  [[ "$output" != *"secret noise"* ]]
}

@test "compact: failure dumps captured output and exits with the command's code" {
  run_sourced compact "$PROJECT_ROOT/02-main.sh" <<'EOF'
boom() { echo "context line"; echo "stderr line" >&2; return 7; }
step "Bad" boom
echo "SHOULD NOT RUN"
EOF
  [ "$status" -eq 7 ]
  [[ "$output" == *"✗  (exit 7)"* ]]
  [[ "$output" == *"context line"* ]]
  [[ "$output" == *"stderr line"* ]]
  [[ "$output" != *"SHOULD NOT RUN"* ]]
}

@test "full: streams output live and ignores --summary" {
  run_sourced full "$PROJECT_ROOT/02-main.sh" <<'EOF'
fake() { echo "live output line"; }
step "Step" --summary 'whatever' fake
EOF
  [ "$status" -eq 0 ]
  [[ "$output" == *"live output line"* ]]
}
