export LARAVEL_ENV_ENCRYPTION_KEY=""
export GITHUB_TOKEN=""

# Avoid not a git repo error
cd {RELEASE}
git init -b main -q
git remote add origin https://github.com/{REPOSITORY_USER}/{REPOSITORY_NAME}.git