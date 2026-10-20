#!/usr/bin/env bash

# Claude Code remote-control, with tmux usage
# cc-remote-control.sh <session> [dir] [profile]
set -euo pipefail

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  echo "Usage: cc-remote-control.sh NAME [DIR] [PROFILE]"
  echo
  echo "Create or re-attach to a tmux session named NAME, cd'd into DIR"
  echo "(default: \$PWD), running 'claude --remote-control'. If PROFILE is"
  echo "given, run it via cc-as.sh under \$HOME/.claude-PROFILE instead of"
  echo "the default ~/.claude config."
  exit 0
fi

NAME="${1:?Usage: cc-remote-control.sh NAME [DIR] [PROFILE]}"
DIR="${2:-$PWD}"
PROFILE="${3:-}"

if [ -n "$PROFILE" ]; then
  CMD="cc-as.sh '$PROFILE' --remote-control --name '$NAME'"
else
  CMD="claude --remote-control --name '$NAME'"
fi

tmux new-session -As "$NAME" -c "$DIR" "$CMD"
