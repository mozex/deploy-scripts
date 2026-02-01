# Ploi Zero-Downtime Deployment Scripts

Centralized deployment scripts for Laravel applications using Ploi.io with zero-downtime deployments via GitHub API.

## Ploi Pre-Deploy Script

```bash
export LARAVEL_ENV_ENCRYPTION_KEY="base64:..."
export GITHUB_TOKEN="github_pat_..."
export RELEASE="{RELEASE}"
export REPOSITORY_USER="{REPOSITORY_USER}"
export REPOSITORY_NAME="{REPOSITORY_NAME}"
export COMMIT_HASH="{COMMIT_HASH}"
export RELOAD_PHP_FPM="{RELOAD_PHP_FPM}"

curl -fsSL -H "Authorization: token $GITHUB_TOKEN" \
  https://raw.githubusercontent.com/mozex/deploy-scripts/main/01-pre.sh | bash
```

## Ploi Deploy Script

```bash
curl -fsSL -H "Authorization: token $GITHUB_TOKEN" \
  https://raw.githubusercontent.com/mozex/deploy-scripts/main/02-main.sh | bash
```

## Ploi Post-Deploy Script

```bash
curl -fsSL -H "Authorization: token $GITHUB_TOKEN" \
  https://raw.githubusercontent.com/mozex/deploy-scripts/main/03-post.sh | bash
```