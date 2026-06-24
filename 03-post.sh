#!/bin/bash
set -eo pipefail

cd "$RELEASE"

# See 02-main.sh for the meaning of DEPLOY_OUTPUT and the step() helper.
DEPLOY_OUTPUT="${DEPLOY_OUTPUT:-full}"

step() {
  local label="$1"; shift
  local summary_re=""
  if [ "$1" = "--summary" ]; then summary_re="$2"; shift 2; fi

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

step "🔄  Reloading PHP-FPM..." reload_php_fpm
step "🌅  Optimizing Activation..." composer deploy:after
