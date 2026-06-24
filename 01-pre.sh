#!/bin/bash
# shellcheck disable=SC2154  # RELEASE, REPOSITORY_USER, etc. are provided by Ploi as environment variables.
set -euo pipefail

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

main() {
  require_env RELEASE REPOSITORY_USER REPOSITORY_NAME COMMIT_HASH GITHUB_TOKEN LARAVEL_ENV_ENCRYPTION_KEY
  cd "$RELEASE"

  git init -b main -q
  local url="https://github.com/${REPOSITORY_USER}/${REPOSITORY_NAME}.git"
  git remote add origin "$url" 2>/dev/null || git remote set-url origin "$url"
}

# Run the deploy unless the test suite sourced this file just for its functions.
[ "${PLOI_DEPLOY_SOURCE_ONLY:-0}" = "1" ] || main
