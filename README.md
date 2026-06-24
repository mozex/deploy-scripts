# Ploi Zero-Downtime Deployment Scripts

[![Tests](https://github.com/mozex/deploy-scripts/actions/workflows/ci.yml/badge.svg)](https://github.com/mozex/deploy-scripts/actions/workflows/ci.yml)

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

## Output Modes

A deploy prints a lot: every Composer package extracted, every Vite asset built, every published file. On a large app that's over a thousand lines, and streaming all of it live can lock up a browser tab watching the Ploi log.

The `DEPLOY_OUTPUT` variable controls how much you see:

| Value | Behavior |
|-------|----------|
| `full` (default) | Streams every command's output live, exactly as before. Nothing changes if you don't set the variable. |
| `compact` | Hides each step's output. On success you get one line per step, like `🚚  Running Composer... ✓  (301 installs)`. If a step fails, its full output is printed right before the deploy aborts, so you keep everything you need to debug. |

A successful deploy in compact mode is about ten lines instead of a thousand.

Set it in the Pre Deploy script (the value is inherited by all three phases):

```bash
export DEPLOY_OUTPUT="compact"
```

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
export SITE_COMPOSER="{SITE_COMPOSER}"

# Optional: "compact" hides each step's output and only shows it if a step fails.
# Leave it unset (or "full") for the current verbose output.
# export DEPLOY_OUTPUT="compact"

curl -fsSL https://raw.githubusercontent.com/mozex/deploy-scripts/main/01-pre.sh | bash
```

`SITE_COMPOSER` pins Composer, and the `@php artisan` commands your deploy scripts run, to the site's configured PHP version instead of the server's default. Ploi expands it to something like `php8.2 /usr/local/bin/composer`. If you leave it out, the scripts fall back to a bare `composer`.

### 2. Main Deploy Script

```bash
curl -fsSL https://raw.githubusercontent.com/mozex/deploy-scripts/main/02-main.sh | bash
```

### 3. Post Deploy Script

```bash
curl -fsSL https://raw.githubusercontent.com/mozex/deploy-scripts/main/03-post.sh | bash
```

## Testing

The scripts are covered by a [bats](https://github.com/bats-core/bats-core) suite and linted with [ShellCheck](https://www.shellcheck.net), both run on every push through GitHub Actions.

To run them locally:

```bash
shellcheck 01-pre.sh 02-main.sh 03-post.sh
bats tests/
```

The tests mock `composer`, `wget`, and `tar` inside a throwaway sandbox, so nothing touches a real server. They cover the compact and full output modes, the failure-dump path, the environment-variable validation, and the storage symlink.

## Security

These scripts run with full access on your production server. Loading them from someone else's GitHub account is a trust decision you should take seriously.

**Fork this repository** to your own GitHub account and update the `curl` URLs to point at your fork. This way you control exactly what runs during deployment. The repository is public so you can review every line before using it.

Alternatively, copy the contents of each script directly into Ploi's text fields instead of loading them from GitHub.

## License

MIT
