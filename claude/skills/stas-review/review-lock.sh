#!/usr/bin/env bash
# Serialize Docker work between review sessions on this machine.
#   review-lock.sh acquire <label>  wait for the lock, then keep it in a
#                                   detached holder for REVIEW_LOCK_MAX (3h)
#   review-lock.sh release <label>  drop the lock held under <label>
#   review-lock.sh status           show who holds it
# The holder expires on its own, so a lost session can't block others forever.
set -euo pipefail

lock=${REVIEW_LOCK:-$HOME/tmp/.ddev-review.lock}
owner=$lock.owner
mkdir -p "$HOME/tmp"

holder_alive() {
	local pid lbl
	read -r pid lbl _ 2>/dev/null <"$owner" || return 1
	[ "$(ps -p "$pid" -o comm= 2>/dev/null)" = sleep ] && echo "$lbl"
}

# Holders that have the lock file open, whatever the owner file says.
lock_holders() {
	local p
	for p in $(pgrep -x sleep); do
		[ "$(readlink "/proc/$p/fd/9" 2>/dev/null)" = "$lock" ] && echo "$p"
	done
	return 0
}

case ${1:-} in
acquire)
	label=${2:?usage: review-lock.sh acquire <label>}
	if [ "$(holder_alive)" = "$label" ]; then
		echo "already held: $(cat "$owner")"
		exit 0
	fi
	exec 9>>"$lock"
	if ! flock -n 9; then
		echo "waiting for: $(cat "$owner" 2>/dev/null || echo "unknown holder, see status")"
		flock 9
	fi
	setsid sleep "${REVIEW_LOCK_MAX:-3h}" </dev/null >/dev/null 2>&1 &
	echo "$! $label $(date -Is)" >"$owner"
	echo "acquired: $(cat "$owner")"
	;;
release)
	label=${2:?usage: review-lock.sh release <label>}
	read -r pid lbl _ 2>/dev/null <"$owner" || { echo "not held"; exit 0; }
	if [ "$(holder_alive)" != "$label" ]; then
		echo "not held by $label: $(cat "$owner")"
		exit 1
	fi
	# Remove the owner file first: the kill lets a waiter in, and it writes its own.
	rm -f "$owner"
	kill "$pid"
	echo "released: $label"
	;;
status)
	if lbl=$(holder_alive); then
		echo "held: $(cat "$owner")"
	elif flock -n "$lock" true; then
		echo "free"
	else
		echo "held by an unknown holder: $(lock_holders | xargs) (kill it if no review owns it)"
	fi
	;;
*)
	echo "usage: review-lock.sh acquire|release <label> | status" >&2
	exit 2
	;;
esac
