#!/bin/bash
set -e

cd "$RELEASE"

echo ""
echo "🔄  Reloading PHP-FPM..."
eval "$RELOAD_PHP_FPM"

echo ""
echo "🌅  Optimizing Activation..."
composer deploy:after