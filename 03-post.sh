#!/bin/bash
# shellcheck disable=SC2154  # RELEASE, RELOAD_PHP_FPM, etc. are provided by Ploi.
set -euo pipefail

# See 02-main.sh for the meaning of DEPLOY_OUTPUT and the step() helper.
DEPLOY_OUTPUT="${DEPLOY_OUTPUT:-full}"

# Abort the deploy with a clear message if any named variable is empty or unset.
require_env() {
  local missing=0 name
  for name in "$@"; do
    if [ -z "${!name:-}" ]; then
      echo "Deploy aborted: required variable '$name' is not set." >&2
      missing=1
    fi
  done
  [ "$missing" -eq 0 ] || exit 1
}

step() {
  local label="$1"; shift
  local summary_re=""
  if [ "${1:-}" = "--summary" ]; then summary_re="$2"; shift 2; fi

  if [ "$DEPLOY_OUTPUT" != "compact" ]; then
    echo ""
    echo "$label"
    "$@"
    return
  fi

  local log; log="$(mktemp)"
  printf '\n%s ' "$label"
  if "$@" >"$log" 2>&1; then
    local note=""
    [ -n "$summary_re" ] && note="$(grep -oE "$summary_re" "$log" | head -n1 || true)"
    if [ -n "$note" ]; then echo "✓  ($note)"; else echo "✓"; fi
    rm -f "$log"
  else
    local code=$?
    echo "✗  (exit $code)"
    echo "────────────────────────── output ──────────────────────────"
    cat "$log"
    echo "─────────────────────────────────────────────────────────────"
    rm -f "$log"
    exit "$code"
  fi
}

reload_php_fpm() { eval "$RELOAD_PHP_FPM"; }

main() {
  require_env RELEASE RELOAD_PHP_FPM
  cd "$RELEASE"

  local -a composer_cmd
  read -ra composer_cmd <<< "${SITE_COMPOSER:-composer}"

  step "🔄  Reloading PHP-FPM..." reload_php_fpm
  step "🌅  Optimizing Activation..." "${composer_cmd[@]}" deploy:after
}

# Run the deploy unless the test suite sourced this file just for its functions.
[ "${PLOI_DEPLOY_SOURCE_ONLY:-0}" = "1" ] || main
