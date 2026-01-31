cd {RELEASE}

{RELOAD_PHP_FPM}

echo ""
echo "🌅  Optimizing Activation..."
composer deploy:after