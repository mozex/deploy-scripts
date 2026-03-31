# Ploi Zero-Downtime Deployment Scripts

Zero-downtime deployment scripts for Laravel applications on [Ploi.io](https://ploi.io). These scripts replace Ploi's default copy-based deployment with a fresh clone from GitHub on every deploy.

For the full reasoning behind these scripts, including command ordering, environment encryption, and the composer scripts approach, read the companion blog post: [My Zero-Downtime Deployment Setup for Laravel](https://mozex.dev/blog/8-my-zero-downtime-deployment-setup-for-laravel).

## What These Scripts Do

Ploi's default zero-downtime deployment copies your last successful release and runs `git pull` on top of it. These scripts take a different approach: they download a fresh tarball of the exact commit from the GitHub API, giving you a clean slate on every deployment.

The three scripts map to Ploi's three deployment phases:

| Script | Phase | What It Does |
|--------|-------|-------------|
| `01-pre.sh` | Pre deploy | Validates environment variables, initializes a minimal git repo for Ploi compatibility |
| `02-main.sh` | Main deploy | Clears the release directory, downloads fresh code from GitHub, links shared storage, installs Composer dependencies, runs `composer deploy:before` |
| `03-post.sh` | Post deploy | Reloads PHP-FPM, runs `composer deploy:after` |

The `deploy:before` and `deploy:after` composer scripts are defined in your application's `composer.json`, not in these scripts. This means your deployment commands live in your codebase, version-controlled and portable. See the [blog post](https://mozex.dev/blog/8-my-zero-downtime-deployment-setup-for-laravel) for a detailed walkthrough of what goes in each.

## Prerequisites

- A Laravel application with `deploy:before` and `deploy:after` composer scripts defined in `composer.json`
- A [GitHub personal access token](https://github.com/settings/tokens) with read-only access to your repository
- A `LARAVEL_ENV_ENCRYPTION_KEY` environment variable if you use Laravel's [environment encryption](https://laravel.com/docs/configuration#encrypting-environment-files)

## Setup

Paste these into Ploi's three deployment script sections. Replace `LARAVEL_ENV_ENCRYPTION_KEY` and `GITHUB_TOKEN` with your own values. The `{VARIABLES}` in curly braces are automatically populated by Ploi.

### 1. Pre Deploy Script

```bash
export LARAVEL_ENV_ENCRYPTION_KEY="base64:..."
export GITHUB_TOKEN="github_pat_..."
export RELEASE="{RELEASE}"
export REPOSITORY_USER="{REPOSITORY_USER}"
export REPOSITORY_NAME="{REPOSITORY_NAME}"
export COMMIT_HASH="{COMMIT_HASH}"
export RELOAD_PHP_FPM="{RELOAD_PHP_FPM}"

curl -fsSL https://raw.githubusercontent.com/mozex/deploy-scripts/main/01-pre.sh | bash
```

### 2. Main Deploy Script

```bash
curl -fsSL https://raw.githubusercontent.com/mozex/deploy-scripts/main/02-main.sh | bash
```

### 3. Post Deploy Script

```bash
curl -fsSL https://raw.githubusercontent.com/mozex/deploy-scripts/main/03-post.sh | bash
```

## Security

These scripts run with full access on your production server. Loading them from someone else's GitHub account is a trust decision you should take seriously.

**Fork this repository** to your own GitHub account and update the `curl` URLs to point at your fork. This way you control exactly what runs during deployment. The repository is public so you can review every line before using it.

Alternatively, copy the contents of each script directly into Ploi's text fields instead of loading them from GitHub.

## License

MIT
