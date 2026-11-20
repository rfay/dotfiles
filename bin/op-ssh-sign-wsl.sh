#!/bin/bash
# gpg.ssh.program for WSL2 (set in .gitconfig-wsl2). Git calls this with
# ssh-keygen's arguments. 1Password's Windows op-ssh-sign-wsl.exe signs, but
# it can't read Linux paths like gpg.ssh.allowedSignersFile, so everything
# other than signing (verify, find-principals, check-novalidate) goes to
# Linux ssh-keygen.

find_signer() {
  # Git started outside a login shell (VS Code, services) may lack the
  # Windows directories on PATH.
  command -v op-ssh-sign-wsl.exe && return
  for f in /mnt/c/Users/"$USER"/AppData/Local/Microsoft/WindowsApps/op-ssh-sign-wsl.exe \
           /mnt/c/Users/*/AppData/Local/Microsoft/WindowsApps/op-ssh-sign-wsl.exe; do
    [ -e "$f" ] && echo "$f" && return
  done
  echo "op-ssh-sign-wsl.exe not found; is 1Password installed on Windows?" >&2
  return 1
}

prev=
for arg in "$@"; do
  if [ "$prev" = "-Y" ] && [ "$arg" = "sign" ]; then
    signer=$(find_signer) || exit 1
    exec "$signer" "$@"
  fi
  prev=$arg
done
exec ssh-keygen "$@"
