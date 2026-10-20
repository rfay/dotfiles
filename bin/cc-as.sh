#!/usr/bin/env bash

# Run claude under an isolated config dir, for a separate login/account.
# cc-as.sh PROFILE [claude args...]
set -euo pipefail

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  echo "Usage: cc-as.sh PROFILE [claude args...]"
  echo
  echo "Run claude with CLAUDE_CONFIG_DIR=\$HOME/.claude-PROFILE, so a"
  echo "separate login/account's credentials, settings, and history stay"
  echo "isolated from the default ~/.claude."
  exit 0
fi

PROFILE="${1:?Usage: cc-as.sh PROFILE [claude args...]}"
shift

export CLAUDE_CONFIG_DIR="$HOME/.claude-${PROFILE}"
exec claude "$@"
