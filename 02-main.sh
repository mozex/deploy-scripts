#!/bin/bash
set -eo pipefail

cd "$RELEASE"

# Output mode:
#   full    (default) - stream every command's output live, exactly as before
#   compact           - hide each step's output; print a one-line summary on
#                       success and the full output only if the step fails
# Enable compact mode by exporting DEPLOY_OUTPUT="compact" in the Pre Deploy
# script (it is inherited by this phase).
DEPLOY_OUTPUT="${DEPLOY_OUTPUT:-full}"

# step "<label>" [--summary <regex>] <command...>
# In compact mode the command's output is captured: on success a "✓" is shown
# (with the first <regex> match from the output, if --summary is given), and on
# failure the captured output is dumped before aborting the deploy.
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

fetch_source() {
  shopt -s dotglob
  rm -rf "$RELEASE"/*
  shopt -u dotglob
  wget --progress=dot:mega -O- --header="Authorization: token $GITHUB_TOKEN" \
    "https://api.github.com/repos/${REPOSITORY_USER}/${REPOSITORY_NAME}/tarball/${COMMIT_HASH}" \
    | tar -xz --strip-components=1
}

link_storage() {
  local storage_path; storage_path="$(realpath ../..)/storage"
  [ ! -d "$storage_path" ] && [ -d storage ] && mv storage "$storage_path"
  rm -rf storage
  ln -s "$storage_path" storage
}

step "🏃  Starting deployment..." fetch_source
step "🔗  Linking Storage Directory..." link_storage
step "🚚  Running Composer..." --summary '[0-9]+ installs?' \
  composer install --no-interaction --prefer-dist --optimize-autoloader --no-dev
step "📦  Preparing For Activation..." --summary 'built in [0-9.]+m?s' \
  composer deploy:before

echo ""
echo "🚀 Activating App!"
