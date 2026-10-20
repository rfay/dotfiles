# rfay's dotfiles

Here are the bash, zsh, gitconfig, related dotfiles for rfay.

## Setup

1. Clone this repository
2. Run `./link.sh` to create symlinks and wire up shell startup files
3. Create `~/.bash_secrets` with your API tokens/secrets (see `.bash_secrets.example`)
4. Optionally create `~/.shell-extra` and `~/.gitconfig.local` for
   per-machine settings (see `.shell-extra.example` and
   `.gitconfig.local.example`)

This repo is public. `link.sh` sets `core.hooksPath` so that
`githooks/pre-commit` refuses commits that add token-shaped strings, private
keys, or files such as `.claude.json`. It uses `gitleaks` as well when that
is installed. For a false positive, commit with `--no-verify`.

`link.sh` is safe to re-run any time (e.g. after `git pull`, or after adding a
new item to `LINKITEMS`) — it never overwrites something it doesn't recognize
without backing it up first, and it skips anything already set up correctly.

This repo targets bash (including macOS's stock bash 3.2), zsh, and
git-bash on Windows. On git-bash specifically, `ln -s` only creates a real
NTFS symlink if `MSYS=winsymlinks:nativestrict` is set *and* the process
has permission to create symlinks (Windows Developer Mode enabled, or an
elevated shell) — otherwise Windows silently falls back to copying files.
`shell/bash_profile` exports that variable for future shells, but on a
brand new machine it won't be set yet for the very first run, so export it
yourself before running `link.sh` the first time:

```bash
export MSYS=winsymlinks:nativestrict
./link.sh
```

`link.sh` will warn if it detects git-bash without that variable set.

## How the shell rc files are wired up

Most files in this repo (`.gitconfig`, `.oh-my-zsh`, the scripts in `bin/`,
etc.) are plain symlinks into `$HOME` — safe, because nothing else on the
machine expects to own those filenames.

`~/.bash_profile`, `~/.bashrc`, and `~/.zshrc` are different: a fresh OS
install, package manager, or another tool may already have opinions about
those exact files. Symlinking over them would silently destroy whatever was
there. So instead, this repo's shell content lives in non-canonical
filenames (`shell/bash_profile`, `shell/bashrc`, `shell/zshrc`), and
`link.sh` appends a small block to your *actual* `~/.bash_profile` /
`~/.bashrc` / `~/.zshrc` that sources the matching repo file:

```bash
# >>> rfay dotfiles: do not edit between these markers, edit the repo instead >>>
[ -r "$HOME/workspace/dotfiles/shell/bashrc" ] && source "$HOME/workspace/dotfiles/shell/bashrc"
# <<< rfay dotfiles <<<
```

The path is written as `$HOME/...` when the repo is under your home directory,
and as an absolute path otherwise. Blocks injected by older versions of
`link.sh` hold the absolute path; both forms work.

Whatever was already in that file (Debian's default `.bashrc` skeleton, a
Homebrew installer's append, a corporate profile script, ...) is left alone
above that block. If the file had real content before `link.sh` ever
touched it, that content is copied to e.g. `~/.bashrc.pre-dotfiles.bak`
first, so nothing is ever lost. Re-running `link.sh` is idempotent — it
detects the marker block and leaves an already-wired file untouched.

### Migrating a machine set up before this change

Older versions of this repo (`baselink.sh` / `relink.sh`) symlinked
`~/.bash_profile`, `~/.bashrc`, and `~/.zshrc` **directly** into the repo,
so on any machine set up that way those three files are themselves
symlinks. After pulling this update:

```bash
git pull
./link.sh
```

`link.sh` detects that the old symlink points into this repo, removes it,
and replaces it with a real file containing the source block above — no
manual steps needed. Until you re-run it, those three files are dangling
symlinks (pointing at filenames that no longer exist at the repo root,
since the content moved to `shell/`), which just means your shell startup
silently no-ops rather than erroring — it's safe to leave for a bit, but
run `./link.sh` on each such machine when convenient.

## Secrets

`~/.bash_secrets` holds machine-local secrets and API tokens that should
never be committed — see `.bash_secrets.example` for the template. It is:
- NOT committed to git (listed in `.gitignore`)
- sourced automatically by both `shell/bashrc` and `shell/zshrc`

```bash
cp .bash_secrets.example ~/.bash_secrets
# edit ~/.bash_secrets and fill in your actual tokens
```

## SSH agent (optional)

`.bash_sshagent` auto-launches (and reuses across shells) an `ssh-agent`
process — handy on a plain Linux/WSL box with no agent already running.
It's deliberately left out of `link.sh`'s symlinks (`NOLINKITEMS` in the
script) because most machines already have an agent going some other way
(1Password SSH agent, macOS Keychain, the 1Password bridges described
below), and auto-linking it everywhere would fight with those.

`shell/zshrc` sources it if present; `shell/bash_profile` has the
equivalent line commented out, since bash setups more often already have
an agent. To opt in on a machine that needs it:

```bash
ln -s ~/dotfiles/.bash_sshagent ~/.bash_sshagent
```

(adjust the path to wherever you cloned this repo), and uncomment the
matching line in `shell/bash_profile` if you're using bash.

## 1Password SSH agent on macOS

1Password serves the agent itself at
`~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock` once
**Settings** > **Developer** > **Use the SSH agent** is on. On macOS,
`link.sh` points three kinds of client at it:

- **`ssh`**, through `IdentityAgent ~/.1password/agent.sock` in
  `.ssh/1password.conf`. `link.sh` symlinks that into `~/.ssh` and adds
  an `Include` of it, inside a marker block, at the top of
  `~/.ssh/config`. It doesn't own the rest of that file, because Coder,
  OrbStack, and Upsun write to it too. `~/.1password/agent.sock` is a
  symlink `link.sh` makes to the real socket, the optional step in
  1Password's setup docs, so the path matches Linux and WSL2 and has no
  space to quote.
- **Shells**: `shell/ssh_agent` sets `SSH_AUTH_SOCK` for bash and zsh,
  which `ssh-add`, DDEV, and other agent clients read.
- **GUI apps launched from the Dock or Finder**, which never read shell
  startup files: the `com.1password.SSH_AUTH_SOCK` launchd agent from
  1Password's compatibility docs, in `launchd/`. At login it replaces
  launchd's own `SSH_AUTH_SOCK` socket with a symlink to 1Password's.

Without these, `SSH_AUTH_SOCK` is launchd's empty built-in agent and
`ssh-add -l` reports no identities even though `ssh` works.

`link.sh` copies launchd plists into `~/Library/LaunchAgents` rather
than symlinking them, since launchd doesn't reliably load a symlinked plist
at login, and reloads any that changed. A replaced plist is backed up to
`~/Library/LaunchAgents.pre-dotfiles/`.

To check, in a new shell:

```bash
echo $SSH_AUTH_SOCK        # ends in com.1password/t/agent.sock
ssh-add -l                 # should list your 1Password keys
ls -l "$(launchctl getenv SSH_AUTH_SOCK)"   # symlink to 1Password's socket
```

## 1Password SSH agent on a Parallels guest

On a Linux guest running under Parallels on a Mac, ssh keys come from the
1Password SSH agent on the host. That is wired up in two halves, and both
have to be present or ssh fails:

- **The socket bridge**, `systemd/1password-bridge.service`: a `socat`
  user unit relaying `~/.1password-agent.sock` to the host's agent on
  `10.211.55.2:2222`.
- **The environment variable**, set in `shell/ssh_agent`: points
  `SSH_AUTH_SOCK` at that socket, but only when the host port answers.

`link.sh` installs and enables the unit automatically, but **only when
`systemd-detect-virt` reports `parallels`** — the hardcoded `10.211.55.2`
is the Parallels shared-network gateway and means nothing on WSL2, bare
metal, or macOS. Everywhere else the step is a silent no-op. It needs
`socat` (`sudo apt install socat`); if that's missing the script warns and
carries on rather than failing.

The Mac side is the `com.1password.socat` launchd agent in `launchd/`: a
`socat` listener on `10.211.55.2:2222` relaying to 1Password's socket.
`link.sh` installs it on a Mac with Parallels Desktop and `socat`
(`brew install socat`). Any guest on the Parallels shared network can
reach that port, and through it your agent.

To check it's healthy:

```bash
systemctl --user status 1password-bridge.service
ssh-add -l                 # should list your 1Password keys
ssh -T git@github.com      # should greet you by username
```

### If `ssh-add -l` says "Connection refused"

`SSH_AUTH_SOCK` is set but nothing is serving the socket, i.e. the bridge
is down. Check `systemctl --user status 1password-bridge.service` first.

The failure worth recognizing is a crash loop logging:

```text
E "/home/rfay/.1password-agent.sock" exists
```

`socat`'s `UNIX-LISTEN` will not bind over an existing socket file, and a
suspended or hard-killed VM leaves one behind. With `Restart=always` the
service then retries forever and never recovers on its own. The
`unlink-early` option in the unit exists to prevent exactly this by
clearing the stale socket before binding — if you ever edit that
`ExecStart` line, keep it. To recover a machine still stuck this way:

```bash
rm -f ~/.1password-agent.sock
systemctl --user restart 1password-bridge.service
```

If instead `SSH_AUTH_SOCK` is empty, the host port wasn't reachable when
your shell started — check 1Password is running on the Mac, then open a
new login shell.

## 1Password SSH agent on WSL2

On WSL2, 1Password runs on Windows and listens only on the named pipe
`\\.\pipe\openssh-ssh-agent`. Linux programs can't open a Windows pipe,
so a bridge serves it as a Unix socket, `~/.1password/agent.sock`, and
Linux `ssh`, `ssh-add`, git, and DDEV's containers all use that socket.
Again two halves, both required:

- **The socket bridge**, `systemd/1password-wsl2-bridge.service`: a
  `socat` user unit that runs `npiperelay.exe` for each connection to
  relay it to the Windows pipe.
- **The environment variable**, set in `shell/ssh_agent`: under WSL2,
  points `SSH_AUTH_SOCK` at the socket, but only if it exists.

The socket has its own directory, not `~/.ssh` or `$HOME` itself,
because DDEV mounts the socket's directory into its `ddev-ssh-agent`
container.

### Setting it up on a new machine

1. In the Windows 1Password app, turn on **Settings** > **Developer** >
   **Use the SSH agent**. 1Password takes over the pipe, so the Windows
   **OpenSSH Authentication Agent** service must be stopped and disabled.
2. WSL2 needs systemd; `/etc/wsl.conf` must contain:

   ```ini
   [boot]
   systemd=true
   ```

   Run `wsl --shutdown` in PowerShell after changing it.
3. Install the two halves of the relay. `npiperelay` is x64-only; Windows
   on Arm runs it under emulation.

   ```bash
   sudo apt install socat                    # in WSL2
   winget install albertony.npiperelay       # in PowerShell
   ```

4. Open a new WSL2 shell (so `npiperelay.exe` is on PATH) and run
   `./link.sh`. Under WSL2 it symlinks `~/bin/npiperelay.exe` to the
   winget copy, because systemd units don't get the Windows PATH and the
   real path contains the Windows username. Then it links and enables the
   unit. It warns and skips the unit if `socat` or `npiperelay.exe` is
   missing.
5. Open a new shell and check:

   ```bash
   systemctl --user status 1password-wsl2-bridge.service
   echo $SSH_AUTH_SOCK        # ~/.1password/agent.sock
   ssh-add -l                 # should list your 1Password keys
   ssh -T git@github.com      # should greet you by username
   ```

6. For DDEV, relay its containers to the same agent once:

   ```bash
   ddev config global --ssh-agent-upstream=$HOME/.1password/agent.sock
   ddev auth ssh              # lists the keys containers can use
   ```

Commit signing in `.gitconfig-wsl2` still uses 1Password's Windows
`op-ssh-sign-wsl.exe`, which talks to 1Password directly and doesn't need
the bridge.

If `ssh-add -l` fails, check the unit first. `journalctl --user -u
1password-wsl2-bridge.service` shows its log; a unit that runs but can't
reach 1Password usually means 1Password is locked or its SSH agent is
off. Restarting the unit doesn't disturb DDEV, which reconnects on its own.

### Unwinding the old `ssh.exe` setup

Before the bridge, WSL2 used the Windows OpenSSH programs directly, which
work with 1Password but give Linux programs and DDEV no socket. On a
machine set up that way:

1. Remove the symlinks that put Windows OpenSSH first on PATH:

   ```bash
   ls -l /usr/local/bin/ssh /usr/local/bin/ssh-add   # -> .../System32/OpenSSH/*.exe
   sudo rm /usr/local/bin/ssh /usr/local/bin/ssh-add
   ```

2. `git pull` this repo. `.gitconfig-wsl2` no longer sets
   `core.sshCommand = ssh.exe`, so git uses Linux `ssh` through the bridge.
   If `git config --show-origin core.sshCommand` still prints anything,
   remove that setting.
3. Follow the setup steps above, then check that `type -a ssh` shows
   `/usr/bin/ssh` first and that `ssh -T git@github.com` works.

## 1Password SSH agent on Windows (git-bash)

On Windows, the 1Password SSH agent listens on the named pipe
`\\.\pipe\openssh-ssh-agent`, which only Windows' own OpenSSH
(`C:\Windows\System32\OpenSSH`) can talk to. Git for Windows ships its own
`ssh` in `/usr/bin`, which can't, so with that one first on PATH
`ssh git@github.com` fails with `Permission denied (publickey)`. This
comes back after any Git reinstall that picks the bundled OpenSSH.

Two pieces handle it:

- `shell/bash_profile` puts `/c/Windows/System32/OpenSSH` ahead of Git's
  ssh on PATH inside git-bash, for `ssh`, `ssh-add`, and `scp`.
- `link.sh` sets `core.sshCommand = C:/Windows/System32/OpenSSH/ssh.exe`
  in `~/.gitconfig.local`, so git uses it everywhere, including from
  VS Code and PowerShell. It goes there rather than in the shared
  `.gitconfig` because that file is also used on macOS and Linux.

Check it with `ssh -T git@github.com` in a new git-bash window.

## Multiple Claude Code logins

Claude Code keeps its credentials, config, and history under `~/.claude` and
`~/.claude.json` by default, and honors `CLAUDE_CONFIG_DIR` to relocate that
whole directory elsewhere. `bin/cc-as.sh` uses this to run `claude` under an
isolated config dir per named profile, so two (or more) logins can run at
the same time on one machine without one clobbering the other's
credentials:

```bash
cc-as.sh work           # runs claude with CLAUDE_CONFIG_DIR=~/.claude-work
cc-as.sh personal        # a separate login, ~/.claude-personal
```

The first time you use a new profile, log in under it — either run
`cc-as.sh work` and `/login` inside the interactive session, or
non-interactively: `cc-as.sh work auth login`. Either way this creates
`~/.claude-work` with its own credentials, settings, and history.

To run a profile as a named, re-attachable background session (via
`bin/cc-remote-control.sh`'s tmux + `claude --remote-control` wrapper), pass
the profile as a third argument:

```bash
cc-remote-control.sh work-session ~/code/work-repo work
```

This creates (or re-attaches to) a tmux session named `work-session`, cd'd
into `~/code/work-repo`, running `claude --remote-control` under the `work`
profile's config dir. Omit the profile argument to use the default
`~/.claude` config, same as before.

### VS Code

The Claude Code VS Code extension reads `CLAUDE_CONFIG_DIR` from its own
process environment too, not just from integrated terminals — so a whole
VS Code window can be pinned to a profile (chat sidebar and inline diffs
included, not just terminals inside it) by launching it with that variable
already set. `bin/code-as.sh` does this:

```bash
code-as.sh work ~/code/work-repo
```

This opens VS Code on `~/code/work-repo` with `CLAUDE_CONFIG_DIR=~/.claude-
work` set, so the extension's own Claude usage in that window authenticates
as the `work` profile — no need to touch the extension's built-in account
switcher. Launch another window with `code-as.sh personal ...` to run a
second login side by side.

## Claude Code skills

`claude/skills/` holds global Claude Code skills, built from the requests
rfay makes most often across projects:

| Skill | For |
| --- | --- |
| `commit-pr` | Committing with a repo's PR template, then `gh pr create` from the `rfay` fork |
| `pr-review` | Reviewing a PR or branch against `upstream/main`, with optional manual testing |
| `ci-failure` | Diagnosing GitHub Actions and Buildkite failures, including intermittent ones |
| `gh-comment` | Posting a labeled Claude comment on an issue or PR |
| `writeup` | Writing a status or findings summary to `~/tmp/<date>_<topic>.md` |

`link.sh` symlinks each skill directory into `~/.claude/skills/`, and into
the `skills/` of any `cc-as.sh` profile directory (`~/.claude-<name>`) that
already exists; re-run it after creating a new profile. Skills are linked one
by one because spec-kitty and decodie install their own skills in the same
directory. A real directory with the same name as one of these is left alone
with a warning.

A repo's own skills and `AGENTS.md` take precedence: `commit-pr`, for
example, defers to the `ddev-commit` skill inside ddev and ddev.com.
`ci-failure` reads Buildkite logs with `bk`, which needs `bk configure` or
`BUILDKITE_API_TOKEN` in `~/.bash_secrets`.

To add a skill, create `claude/skills/<name>/SKILL.md` and re-run `link.sh`.
Edits to existing skills take effect immediately through the symlink.

## Prerequisites

Consider installing:
* Build essentials: `sudo apt install build-essential ccache jq python3-pip`
* Golang: `brew install golang` or `sudo snap install --classic go`
* Utilities: `sudo apt install -y autojump nsis unzip zip`
* Homebrew: `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
* Dev tools: `brew install -y golangci-lint nodejs npm`
* Markdown linter: `sudo npm install -g markdownlint-cli`
* MkDocs: `sudo pip3 install -r docs/mkdocs-pip-requirements`
* 1Password on WSL2: see [1Password SSH agent on WSL2](#1password-ssh-agent-on-wsl2)
* NSIS: `sudo ../ddev/.ci-scripts/nsis_setup.sh /usr/share/nsis`
