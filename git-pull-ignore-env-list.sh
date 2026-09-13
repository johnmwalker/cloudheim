#!/bin/bash
# ============================================================================
# git-pull-ignore-env-list.sh — on-instance maintenance script
# ============================================================================
# Purpose: update /cloudheim from origin WITHOUT tripping over env.list.
#
# The repo's env.list must never contain real PASSWORD/WEBHOOK_URL values
# (the autosave timer commits from this tree, so secrets here = leaked
# secrets). They live outside the repo in SECRETS_FILE and are appended to
# env.list AFTER every pull — appends win, because docker compose env_file
# resolves duplicate keys last-wins and the repo's placeholders are comments.
#
# Steady state is the Launch/Shutdown GitHub Actions workflows; this script
# is only for editing the live instance on the fly.
#
# Usage:
#   sudo ./git-pull-ignore-env-list.sh            # pull + re-apply secrets
#   sudo ./git-pull-ignore-env-list.sh --restart  # ...then apply to container
# ============================================================================
set -euo pipefail

SECRETS_FILE=/home/ubuntu/.cloudheim-secrets

if [ "$(id -u)" -ne 0 ]; then
  echo "Run with sudo (the repo and volumes are root/uid-111 managed)." >&2
  exit 1
fi

cd /cloudheim

# --- 1. Make sure the secrets are persisted outside the repo ----------------
# First run: rescue them out of env.list. Later runs: re-rescue so that
# values pasted directly into env.list since the last run are kept.
if grep -qE '^(PASSWORD|WEBHOOK_URL)=..*' env.list; then
  grep -E '^(PASSWORD|WEBHOOK_URL)=..*' env.list > "$SECRETS_FILE"
  chmod 600 "$SECRETS_FILE"
  echo "Secrets persisted to $SECRETS_FILE"
elif [ ! -s "$SECRETS_FILE" ]; then
  echo "ERROR: no PASSWORD/WEBHOOK_URL in env.list and $SECRETS_FILE is" >&2
  echo "empty. Nothing to preserve — refusing to continue (a pull now" >&2
  echo "would leave env.list without a password and startup.sh would" >&2
  echo "abort after the next recreate anyway)." >&2
  exit 1
fi

# --- 2. Clean env.list so the pull can fast-forward -------------------------
# Local env.list modifications are secrets-only by design, so discarding
# them is safe: they are already saved in $SECRETS_FILE.
git checkout -- env.list

# --- 3. Pull (ff-only: fail loudly instead of merging a weird tree) ---------
if ! git pull --ff-only; then
  echo "ERROR: git pull failed. Usually staged/modified world files from" >&2
  echo "the autosave timer. Check 'git status'; commit or reset the world" >&2
  echo "files (keep only saves with a _main.*.ok marker), then re-run." >&2
  exit 1
fi

# --- 4. Re-append the secrets (last key wins in compose env_file) -----------
cat "$SECRETS_FILE" >> env.list

# --- 5. Verify — show only that the keys exist, never their values ----------
echo
echo "env.list secret keys present:"
sed -E 's/^(PASSWORD|WEBHOOK_URL)=.*/\1=<set>/' "$SECRETS_FILE"
grep -cE '^(PASSWORD|WEBHOOK_URL)=..*' env.list | xargs echo "secret lines in env.list:"

# --- 6. Optional: apply to the running container ----------------------------
if [ "${1:-}" = "--restart" ]; then
  bash startup.sh
  docker compose up -d --force-recreate
  echo
  echo "Container recreated. Follow the boot with: docker logs -f valheim"
else
  echo
  echo "Repo updated, secrets re-applied. Apply to the container with:"
  echo "  sudo ./git-pull-ignore-env-list.sh --restart"
fi
