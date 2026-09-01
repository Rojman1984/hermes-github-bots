#!/usr/bin/env bash
# bot-git.sh — push as the hermes-bot identity using the scoped fine-grained PAT.
# Token is read from the machine's .env (never passed on the command line, never
# embedded in remote URLs, never echoed). Git's credential helper receives it
# via a per-invocation helper process.
#
# Usage: bot-git.sh <repo-root> <branch-to-push> [commit-message]
#   With a message: stages all changes, commits as the bot identity, pushes.
#   Without:        sets the bot identity and pushes existing commits.
# Env override: HERMES_ENV=/path/to/.env

set -euo pipefail

ROOT="$1"; BRANCH="$2"
# normalize MSYS-style paths (/c/...) for native git on Windows
command -v cygpath >/dev/null 2>&1 && ROOT=$(cygpath -m "$ROOT")
ENV_FILE="${HERMES_ENV:-$HOME/.hermes/.env}"
if [ ! -f "$ENV_FILE" ] && [ -n "${LOCALAPPDATA:-}" ]; then
  ENV_FILE="$LOCALAPPDATA/hermes/.env"
fi
[ -f "$ENV_FILE" ] || { echo "no .env found (tried $HOME/.hermes/.env and \$LOCALAPPDATA/hermes/.env)" >&2; exit 1; }

GITHUB_BOT_TOKEN=$(grep '^GITHUB_BOT_TOKEN=' "$ENV_FILE" | cut -d= -f2-)
GIT_BOT_NAME=$(grep '^GIT_BOT_NAME=' "$ENV_FILE" | cut -d= -f2- | tr -d '"')
GIT_BOT_EMAIL=$(grep '^GIT_BOT_EMAIL=' "$ENV_FILE" | cut -d= -f2- | tr -d '"')
[ -n "$GITHUB_BOT_TOKEN" ] || { echo "GITHUB_BOT_TOKEN missing in $ENV_FILE" >&2; exit 1; }

git -C "$ROOT" config user.name  "$GIT_BOT_NAME"
git -C "$ROOT" config user.email "$GIT_BOT_EMAIL"

# optional commit as the bot identity (stage all, commit)
if [ $# -ge 3 ]; then
  git -C "$ROOT" add -A
  git -C "$ROOT" commit -m "$3"
fi

# feed the token via credential helper (no token in URL, argv, or .git/config)
git -C "$ROOT" \
  -c credential.helper='!f() { echo "username=hermes-bot"; echo "password=$GITHUB_BOT_TOKEN"; }; f' \
  push origin "$BRANCH"

echo "pushed $BRANCH as ${GIT_BOT_NAME} <${GIT_BOT_EMAIL}> (scoped PAT)"