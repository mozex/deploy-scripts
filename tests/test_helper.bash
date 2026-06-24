#!/usr/bin/env bash
# Shared helpers for the deploy-script test suite.

# Repo root (one level up from this tests/ directory).
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PROJECT_ROOT

# Create an isolated sandbox with a mock-binary directory at the front of PATH.
setup_sandbox() {
  SANDBOX="$(mktemp -d)"
  MOCK_BIN="$SANDBOX/bin"
  mkdir -p "$MOCK_BIN"
  PATH="$MOCK_BIN:$PATH"
  export SANDBOX MOCK_BIN PATH
}

teardown_sandbox() {
  [ -n "${SANDBOX:-}" ] && rm -rf "$SANDBOX"
}

# supports_symlinks: true when `ln -s` produces a real symlink here (Linux CI),
# false on platforms that emulate them (Git Bash on Windows).
supports_symlinks() {
  ln -s target "$SANDBOX/__ln_probe" 2>/dev/null || return 1
  local ok=1
  [ -L "$SANDBOX/__ln_probe" ] && ok=0
  rm -f "$SANDBOX/__ln_probe"
  return $ok
}

# make_mock <name>: read the executable's body from stdin and put it on PATH.
make_mock() {
  local name="$1"
  cat > "$MOCK_BIN/$name"
  chmod +x "$MOCK_BIN/$name"
}

# run_sourced <mode> <script>: source <script> for its functions only (no deploy
# runs) and then execute the driver body read from stdin. Sets bats' $status and
# $output. <mode> becomes DEPLOY_OUTPUT inside the driver.
run_sourced() {
  local mode="$1" target="$2"
  local drv="$SANDBOX/driver.sh"
  { echo 'source "$SCRIPT_UNDER_TEST"'; cat; } > "$drv"
  run env PLOI_DEPLOY_SOURCE_ONLY=1 DEPLOY_OUTPUT="$mode" SCRIPT_UNDER_TEST="$target" \
    bash "$drv"
}
