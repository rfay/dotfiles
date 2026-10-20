#!/usr/bin/env bash

# Launch VS Code with an isolated Claude Code config dir, so the Claude
# Code extension (chat sidebar, inline diffs, etc.) in that window uses a
# separate login/account. See cc-as.sh for the equivalent CLI wrapper.
# code-as.sh PROFILE [code args...]
set -euo pipefail

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  echo "Usage: code-as.sh PROFILE [code args...]"
  echo
  echo "Launch VS Code with CLAUDE_CONFIG_DIR=\$HOME/.claude-PROFILE, so the"
  echo "Claude Code extension in that window uses a separate login/account"
  echo "from the default ~/.claude."
  exit 0
fi

PROFILE="${1:?Usage: code-as.sh PROFILE [code args...]}"
shift

export CLAUDE_CONFIG_DIR="$HOME/.claude-${PROFILE}"
exec code "$@"
