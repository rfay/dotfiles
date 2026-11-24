# AGENTS.md

Guidance for AI agents working on rfay's dotfiles. `README.md` is the
human-facing setup guide; this file covers what an agent needs to avoid
breaking a machine. When behavior changes, update `README.md` too.

## How the repo gets onto a machine

`./link.sh` does all setup and is safe to re-run. It:

- Symlinks every item in `LINKITEMS` into `$HOME` (`.gitconfig`,
  `.oh-my-zsh`, `bin/*`, ...). Anything already a symlink is skipped.
- Injects a marker block into the real `~/.bash_profile`, `~/.bashrc`, and
  `~/.zshrc` that sources `shell/bash_profile`, `shell/bashrc`, and
  `shell/zshrc`. Those three home files are regular files, not symlinks —
  that is expected, not breakage.
- Does per-platform setup that can't live in a shared file: the Parallels
  and WSL2 1Password bridge units, on macOS the `~/.1password/agent.sock`
  symlink, the `~/.ssh/config` Include, and the `launchd/` agents, and on
  Windows the git ssh override below. `launchd/` plists are copied, not
  symlinked, so after editing one re-run `link.sh` to reload it.
- Symlinks each directory in `claude/skills/` into `~/.claude/skills/` (and
  any `~/.claude-<profile>/skills/`). These are global Claude Code skills;
  they live outside `.claude/` so they don't also load as project skills
  here. Keep repo-specific rules in that repo's own skills, not these.
- Symlinks `claude/CLAUDE.md` as `CLAUDE.md` in the same directories. It
  replaces an identical file there, and leaves a different one alone with a
  warning.
- Adds the rules in `claude/permissions.json` to `permissions.allow` in each
  of those directories' `settings.json`, using `jq` or else `python3`. Claude
  Code writes `settings.json` itself, so it is merged, never linked; rules and
  settings already there are kept, and a file that isn't valid JSON is left
  alone with a warning.

**Edit files in the repo, never the linked or injected copies in `$HOME`.**
When a setting has to differ per machine, prefer a `link.sh` step that writes
it over asking the user to do it by hand.

## Every change must work on every platform

The same files run on:

- macOS, including its stock bash 3.2
- Linux: Parallels guests on a Mac, WSL2, bare metal
- Git Bash on Windows (currently an ARM64 build, `/clangarm64/bin/git`)

Guard anything platform-specific with a check for the thing it needs:
`case "$OSTYPE" in msys|cygwin)`, `command -v <tool>`, or `[ -d <path> ]`.
Never hardcode `/Users/rfay`, `/home/rfay`, or `C:\...` in a shared file;
use `~` or `$HOME`.

There are two global git configs, so **a git setting change goes in both
`.gitconfig` and `.gitconfig-wsl2`**:

- `.gitconfig` is used on macOS, Windows, and Linux other than WSL2.
  `.gitconfig.linux` adds to it through `includeIf "gitdir:/home/"`, which
  only fires inside a repo — it does not apply to `git clone` or to commands
  run outside a repo.
- `.gitconfig-wsl2` is used instead on WSL2, where `shell/bash_profile` sets
  `GIT_CONFIG_GLOBAL` to it. It does not include `.gitconfig`.

Both include `~/.gitconfig.local` last, for machine-specific settings. That
file is real and per-machine; the tracked `.gitconfig.local.example` is only a
commented template and is not linked.

Commit signing differs by platform:

- macOS and Windows: `gpg.ssh.program = "op-ssh-sign"`, found on PATH (on
  Windows, in `%LOCALAPPDATA%\Microsoft\WindowsApps`).
- WSL2: `bin/op-ssh-sign-wsl.sh`, which sends signing to 1Password's
  `op-ssh-sign-wsl.exe` and verification to Linux `ssh-keygen`.
- Other Linux: `.gitconfig.linux` turns signing off, since most of these
  hosts don't have the key. `~/.gitconfig.local` turns it back on per host.

## Windows / Git Bash

These all broke on a Git reinstall and took diagnosis to fix:

- **`CLAUDE_CODE_GIT_BASH_PATH`** must be a Windows path to `bash.exe`
  (`C:\...\Git\bin\bash.exe`), because Claude Code is a native Windows
  process. `shell/bash_profile` derives it with `cygpath -w /`. If the Bash
  tool fails to start with `Top-level not found`, the variable or the Git
  install it names is broken; diagnose from PowerShell instead.
- **1Password SSH agent.** On Windows it serves keys on the named pipe
  `\\.\pipe\openssh-ssh-agent`, which only Windows OpenSSH
  (`C:\Windows\System32\OpenSSH`) can read. Git for Windows bundles its own
  ssh in `/usr/bin`, which can't, and fails with
  `Permission denied (publickey)`. Two pieces fix it, and both are needed:
  `shell/bash_profile` puts Windows OpenSSH first on PATH for interactive
  ssh, and `link.sh` sets `core.sshCommand` in `~/.gitconfig.local` for git
  run outside Git Bash (VS Code, PowerShell).
- **Commit signing.** 1Password's "set up signing" can rewrite
  `gpg.ssh.program` in `.gitconfig` to an absolute `C:\...\op-ssh-sign.exe`
  path. **Never commit that;** revert it with `git checkout -- .gitconfig`.
- **Symlinks** are only real under `MSYS=winsymlinks:nativestrict` with
  Developer Mode or an elevated shell; otherwise `ln -s` silently copies.

## `.oh-my-zsh/` is vendored

`.oh-my-zsh/` is a checked-in copy of about 850 files. If `git status` shows
it mass-deleted, that is accidental: restore it with
`git checkout -- .oh-my-zsh` and never commit the deletion. Don't edit files
under it.

## Verifying a change

Test in a fresh login shell, since the current one keeps its old
environment: `bash -lc '<command>'`. For ssh and git:

```bash
ssh -T git@github.com        # should greet rfay by name
ssh-add -l                   # should list the 1Password keys
git ls-remote origin HEAD    # git's own ssh path
```

On Windows, repeat the `git` check from PowerShell to cover git outside Git
Bash. To check signing, make an empty commit in a throwaway repo under
`~/tmp` and run `git log --show-signature -1`; never test by committing here.

## Secrets

**This repo is public.** Its earlier history was discarded (kept privately as
`rfay/dotfiles.old`) because a linked `.claude.json` had committed GitHub and
Upsun tokens along with Claude prompt history. A clone from before that fails
`git pull` with "refusing to merge unrelated histories" or "no such ref was
fetched"; README.md's "Clones from before October 20, 2026" has the recovery
steps. Show the user any unpushed commits or uncommitted changes and get
confirmation before running them, since they discard both.

- Never commit secrets. They go in `~/.bash_secrets`, which the shell files
  source. `~/.bash_secrets`, `~/.shell-extra`, and `~/.gitconfig.local` are
  machine-local; the tracked `*.example` files are their templates.
- **Never link a file into this repo that a program writes to by itself**
  (`~/.claude.json`, `~/.claude/settings.json`, IDE state, shell history).
  Only link files that change when a person edits them in the repo.
- `githooks/pre-commit` blocks commits that add token-shaped strings,
  private keys, or files like `.claude.json`; `link.sh` turns it on with
  `core.hooksPath`. Don't bypass it with `--no-verify` unless the user
  confirms the match is a false positive.
- **Never run a command that prints a credential**, such as `gh auth token`
  or `git credential fill`, even to check that one exists. Output can end up
  in a commit message, a log, or this public repo.

## Git workflow

This is rfay's own repo, so agents may push to it. Commit when asked,
directly on `main`, and push `main` to `origin` with a plain `git push`.
Don't open a PR, and never force-push `main` or push with `--no-verify`.
If the push is rejected because `origin/main` moved, run `git pull` (which
rebases) and push again; stop and ask if the rebase conflicts.

Commit subjects are a short imperative sentence with no Conventional Commits
prefix, for example `Use Windows OpenSSH in git-bash so 1Password's SSH agent
works`. The body says why.

Pass commit messages through a file: write the text with the editor tool,
then `git commit -F <file>`. Don't use `-m` with a heredoc or `bash -c "..."`,
where backticks and `$(...)` inside the message run as commands.

## English language usage

These apply everywhere: conversation, commit messages, code, and comments.

**Never use any of these, in any form:** `comprehensive`, `seamless`,
`genuine`, `genuinely`, `honest`, `honestly`, `truly`, `really` (as an
intensifier), `perfect`, `perfectly`, `robust`, `powerful`, `effortless`,
`production-ready`, `delve`, `elevate`, `unleash`, `to be honest`, `in all
honesty`, `for real`. They assert importance instead of demonstrating it:
delete the word, and if that changes the meaning, the claim needed evidence.

Don't compliment or validate the reader; lead with the substance. Report
results plainly: if something failed, was skipped, or is unverified, say so.

Comments say why, not what, and stay short; longer reasoning belongs in the
commit message. Describe what is true now, not what changed: "moved from X"
goes stale.
