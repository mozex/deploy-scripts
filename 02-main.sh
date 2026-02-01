#!/bin/bash
set -e

cd "$RELEASE"

echo ""
echo "🏃  Starting deployment..."
shopt -s dotglob
rm -rf "$RELEASE"/*
shopt -u dotglob
wget --progress=dot:mega -O- --header="Authorization: token $GITHUB_TOKEN" \
  "https://api.github.com/repos/${REPOSITORY_USER}/${REPOSITORY_NAME}/tarball/${COMMIT_HASH}" \
  | tar -xz --strip-components=1

echo ""
echo "🔗  Linking Storage Directory..."
STORAGE_PATH="$(realpath ../..)/storage"
[ ! -d "$STORAGE_PATH" ] && [ -d storage ] && mv storage "$STORAGE_PATH"
rm -rf storage
ln -s "$STORAGE_PATH" storage

echo ""
echo "🚚  Running Composer..."
composer install --no-interaction --prefer-dist --optimize-autoloader --no-dev

echo ""
echo "📦  Preparing For Activation..."
composer deploy:before

echo ""
echo "🚀 Activating App!"