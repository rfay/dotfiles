#!/bin/bash
#
# Sets up this dotfiles repo on the current machine.
#
# Most files are symlinked directly into $HOME. The shell startup files
# (.bash_profile, .bashrc, .zshrc) are the exception: those are files a
# fresh OS install, package manager, or another tool may already own, so
# instead of replacing them outright we inject a small "source this repo"
# block into whatever is already there (backing up any pre-existing
# content first). See the "How the shell rc files are wired up" section
# of README.md for details.

set -o errexit

LINKITEMS=".gitconfig .gitconfig.linux .gitconfig-wsl2 .gitignore .oh-my-zsh .ssh/allowed_signers bin/cc-as.sh bin/cc-remote-control.sh bin/code-as.sh bin/brewlink_ddev.sh bin/relink_ddev.sh bin/switchcompose.sh bin/unlink_ddev.sh bin/wsl2setup.sh"
NOLINKITEMS=".bash_sshagent"

# target (relative to $HOME) -> source (relative to this repo)
INJECTITEMS=".bash_profile:shell/bash_profile .bashrc:shell/bashrc .zshrc:shell/zshrc"

MARK_BEGIN="# >>> rfay dotfiles: do not edit between these markers, edit the repo instead >>>"
MARK_END="# <<< rfay dotfiles <<<"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

case "$OSTYPE" in
  msys|cygwin)
    if [ "$MSYS" != "winsymlinks:nativestrict" ]; then
      echo "WARNING: running under git-bash without MSYS=winsymlinks:nativestrict set." >&2
      echo "  'ln -s' below may silently create copies instead of real symlinks unless" >&2
      echo "  Developer Mode (or an elevated shell) is enabled on Windows. Run:" >&2
      echo "    export MSYS=winsymlinks:nativestrict" >&2
      echo "  then re-run this script. See README.md for details." >&2
    fi
    ;;
esac

mkdir -p ~/bin ~/.ssh
chmod 700 ~/.ssh
set -x
for item in $LINKITEMS; do
  [ ! -L ~/$item ] && ln -s ${DIR}/$item ~/$item
done
set +x

inject() {
  local target=$1 source_rel=$2
  local target_path="$HOME/$target"
  local source_path="${DIR}/${source_rel}"

  # Migrate machines set up under the old scheme, where $target was itself
  # a symlink straight into this repo: drop the symlink so it can become a
  # real file with the sourcing block below.
  if [ -L "$target_path" ]; then
    case "$(readlink "$target_path")" in
      "$DIR"/*) rm "$target_path" ;;
    esac
  fi

  if [ -e "$target_path" ]; then
    if grep -qF "$MARK_BEGIN" "$target_path"; then
      return 0 # already injected
    fi
    cp "$target_path" "${target_path}.pre-dotfiles.bak"
    echo "Backed up existing $target_path to ${target_path}.pre-dotfiles.bak"
  else
    touch "$target_path"
  fi

  # Write $HOME rather than its expansion when the repo is under it, so the
  # block survives a moved or renamed home directory.
  local source_ref="$source_path"
  case "$source_path" in
    "$HOME"/*) source_ref="\$HOME/${source_path#"$HOME"/}" ;;
  esac

  {
    echo ""
    echo "$MARK_BEGIN"
    echo "[ -r \"$source_ref\" ] && source \"$source_ref\""
    echo "$MARK_END"
  } >> "$target_path"
  echo "Wired $target_path to source $source_path"
}

for pair in $INJECTITEMS; do
  inject "${pair%%:*}" "${pair#*:}"
done

# The 1Password SSH agent bridges are per-platform: a Parallels guest relays
# to the macOS host at 10.211.55.2:2222, and WSL2 relays to the Windows named
# pipe through npiperelay.exe. shell/bash_profile sets SSH_AUTH_SOCK to the
# socket each unit serves, so the two halves have to ship together.
install_1password_bridge() {
  local unit=$1 purpose=$2
  local unit_dir="$HOME/.config/systemd/user"
  local source_path="${DIR}/systemd/${unit}"

  if ! command -v socat >/dev/null 2>&1; then
    echo "WARNING: socat is not installed; skipping $unit. Install it" >&2
    echo "  (sudo apt install socat) and re-run this script, or ssh via the" >&2
    echo "  1Password agent will not work." >&2
    return 0
  fi

  mkdir -p "$unit_dir"

  # Migrate machines where the unit was hand-created as a real file before it
  # was tracked here, so it can become a symlink into the repo like everything
  # else. Anything that is not already our symlink gets backed up first.
  if [ -L "$unit_dir/$unit" ]; then
    [ "$(readlink "$unit_dir/$unit")" = "$source_path" ] || rm "$unit_dir/$unit"
  elif [ -e "$unit_dir/$unit" ]; then
    cp "$unit_dir/$unit" "$unit_dir/${unit}.pre-dotfiles.bak"
    echo "Backed up existing $unit_dir/$unit to $unit_dir/${unit}.pre-dotfiles.bak"
    rm "$unit_dir/$unit"
  fi

  [ -L "$unit_dir/$unit" ] || ln -s "$source_path" "$unit_dir/$unit"

  # A --user systemctl needs a session bus to talk to; it is missing in
  # things like a docker build or a plain `ssh host ./link.sh`.
  if ! systemctl --user show-environment >/dev/null 2>&1; then
    echo "Linked $unit, but no user systemd session is available to enable it."
    echo "  Run this once from a normal login session:"
    echo "    systemctl --user daemon-reload && systemctl --user enable --now $unit"
    return 0
  fi

  systemctl --user daemon-reload
  systemctl --user enable --now "$unit"
  echo "Enabled $unit ($purpose)"
}

# The WSL2 unit can't see the Windows PATH, and npiperelay.exe's real path
# contains the Windows username, so give it a fixed path in ~/bin.
link_npiperelay() {
  local target
  target=$(type -ap npiperelay.exe | grep -v "^$HOME/bin/" | head -n 1)
  if [ -z "$target" ]; then
    echo "WARNING: WSL2 detected but npiperelay.exe is not on PATH; skipping" >&2
    echo "  the 1Password bridge. Run 'winget install albertony.npiperelay' in" >&2
    echo "  PowerShell, open a new WSL2 shell, and re-run this script." >&2
    return 1
  fi
  ln -sfn "$target" ~/bin/npiperelay.exe
}

case "$(systemd-detect-virt 2>/dev/null)" in
  parallels)
    install_1password_bridge 1password-bridge.service "1Password SSH agent bridge to Parallels host"
    ;;
  wsl)
    link_npiperelay && install_1password_bridge 1password-wsl2-bridge.service "1Password SSH agent bridge to Windows"
    ;;
esac

# On Windows, 1Password's SSH agent is a named pipe that only Windows OpenSSH
# can use; git-for-windows bundles its own ssh, which can't. Point git at the
# Windows one in the machine-local config, since the shared .gitconfig is also
# used on macOS/Linux. This covers git run outside git-bash (VS Code, etc.);
# shell/bash_profile handles plain `ssh` in git-bash.
configure_windows_git_ssh() {
  local win_ssh="C:/Windows/System32/OpenSSH/ssh.exe"
  case "$OSTYPE" in msys|cygwin) ;; *) return 0 ;; esac
  [ -x "/c/Windows/System32/OpenSSH/ssh.exe" ] || return 0
  git config --file ~/.gitconfig.local core.sshCommand "$win_ssh"
  echo "Set core.sshCommand=$win_ssh in ~/.gitconfig.local (1Password SSH agent)"
}

configure_windows_git_ssh

# On macOS, give 1Password's agent socket the same ~/.1password/agent.sock path
# it has on WSL2, so ~/.ssh/config can use one IdentityAgent line with no
# space to quote. This is the optional symlink in 1Password's setup docs.
link_macos_1password_sock() {
  local sock="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
  case "$OSTYPE" in darwin*) ;; *) return 0 ;; esac
  if [ -L ~/.1password/agent.sock ] || [ -e ~/.1password/agent.sock ]; then return 0; fi
  mkdir -p ~/.1password
  ln -s "$sock" ~/.1password/agent.sock
  echo "Linked ~/.1password/agent.sock to 1Password's SSH agent socket"
}

link_macos_1password_sock

# ~/.ssh/config is also written by Coder, OrbStack, and Upsun, so rather than
# owning it, put an Include of .ssh/1password.conf at the top. An Include has
# to come before the first Host line to apply to every host.
include_macos_ssh_config() {
  local target="$HOME/.ssh/config"
  case "$OSTYPE" in darwin*) ;; *) return 0 ;; esac
  [ -L ~/.ssh/1password.conf ] || [ -e ~/.ssh/1password.conf ] || ln -s "${DIR}/.ssh/1password.conf" ~/.ssh/1password.conf
  if [ -e "$target" ]; then
    grep -qF "$MARK_BEGIN" "$target" && return 0
    cp "$target" "${target}.pre-dotfiles.bak"
    echo "Backed up existing $target to ${target}.pre-dotfiles.bak"
  fi
  {
    echo "$MARK_BEGIN"
    echo "Include 1password.conf"
    echo "$MARK_END"
    echo ""
    [ -e "$target" ] && cat "$target"
  } > "${target}.dotfiles.tmp"
  chmod 600 "${target}.dotfiles.tmp"
  mv "${target}.dotfiles.tmp" "$target"
  echo "Wired $target to include ~/.ssh/1password.conf"
}

include_macos_ssh_config

# launchd agents are copied, not symlinked, because launchd doesn't reliably
# load a symlinked plist at login. A changed plist is reloaded in place.
install_launch_agent() {
  local label=$1
  local source_path="${DIR}/launchd/${label}.plist"
  local target="$HOME/Library/LaunchAgents/${label}.plist"
  local domain="gui/$(id -u)"

  [ -f "$target" ] && cmp -s "$source_path" "$target" && return 0
  mkdir -p ~/Library/LaunchAgents
  if [ -f "$target" ]; then
    # Outside LaunchAgents, so launchd never sees the backup.
    mkdir -p ~/Library/LaunchAgents.pre-dotfiles
    cp "$target" ~/Library/LaunchAgents.pre-dotfiles/
    echo "Backed up existing $target to ~/Library/LaunchAgents.pre-dotfiles/"
  fi
  cp "$source_path" "$target"
  launchctl bootout "$domain/$label" 2>/dev/null || true
  if launchctl bootstrap "$domain" "$target"; then
    echo "Loaded launchd agent $label"
  else
    echo "WARNING: copied $target but could not load it; it will load at next login." >&2
  fi
}

case "$OSTYPE" in
  darwin*)
    install_launch_agent com.1password.SSH_AUTH_SOCK
    # The Parallels guest's bridge unit connects to this listener.
    if [ -d "/Applications/Parallels Desktop.app" ]; then
      if command -v socat >/dev/null 2>&1; then
        install_launch_agent com.1password.socat
      else
        echo "WARNING: Parallels is installed but socat is not; skipping the" >&2
        echo "  1Password bridge listener. Run 'brew install socat' and re-run." >&2
      fi
    fi
    ;;
esac

# Each skill is linked on its own, not the whole skills directory, because
# other tools (spec-kitty, decodie) install their own skills there too.
# cc-as.sh profiles (~/.claude-<name>) get the same skills.
link_claude_skills() {
  local config_dir skill name target
  mkdir -p ~/.claude/skills
  for config_dir in "$HOME/.claude" "$HOME"/.claude-*/; do
    config_dir=${config_dir%/}
    [ -d "$config_dir" ] || continue
    mkdir -p "$config_dir/skills"
    for skill in "$DIR"/claude/skills/*/; do
      skill=${skill%/}
      name=$(basename "$skill")
      target="$config_dir/skills/$name"
      [ -L "$target" ] && continue
      if [ -e "$target" ]; then
        echo "WARNING: $target exists and is not a symlink; leaving it alone." >&2
        continue
      fi
      ln -s "$skill" "$target"
      echo "Linked Claude skill $name into $config_dir/skills"
    done
  done
}

link_claude_skills

echo "Consider also adding $NOLINKITEMS"
