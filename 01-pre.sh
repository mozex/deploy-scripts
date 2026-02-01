#!/bin/bash
set -e

: "${RELEASE:?RELEASE not set}"
: "${REPOSITORY_USER:?REPOSITORY_USER not set}"
: "${REPOSITORY_NAME:?REPOSITORY_NAME not set}"
: "${COMMIT_HASH:?COMMIT_HASH not set}"
: "${GITHUB_TOKEN:?GITHUB_TOKEN not set}"
: "${LARAVEL_ENV_ENCRYPTION_KEY:?LARAVEL_ENV_ENCRYPTION_KEY not set}"

cd "$RELEASE"
git init -b main -q
git remote add origin "https://github.com/${REPOSITORY_USER}/${REPOSITORY_NAME}.git"