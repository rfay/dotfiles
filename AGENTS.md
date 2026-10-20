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

`.gitconfig` is shared by all of them. Machine-specific git settings go in
`~/.gitconfig.local`, which `.gitconfig` includes last. That file is real and
per-machine; the tracked `.gitconfig.local.example` is only a commented
template and is not linked. `.gitconfig.linux` is pulled in by
`includeIf "gitdir:/home/"`, which only fires inside a repo — it does not
apply to `git clone` or to commands run outside a repo.

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
- **Commit signing** uses `gpg.ssh.program = "op-ssh-sign"`, found on PATH
  on every platform (on Windows, in `%LOCALAPPDATA%\Microsoft\WindowsApps`).
  1Password's "set up signing" can rewrite this in `.gitconfig` to an
  absolute `C:\...\op-ssh-sign.exe` path. **Never commit that;** revert it
  with `git checkout -- .gitconfig`.
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
Bash. To check signing, make an empty commit in a throwaway repo under the
scratch directory and run `git log --show-signature -1`; never test by
committing here.

## Secrets

**This repo is public.** Its earlier history was discarded (kept privately as
`rfay/dotfiles.old`) because a linked `.claude.json` had committed GitHub and
Upsun tokens along with Claude prompt history.

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

## Git workflow

**Commit locally, never publish.** Commit when asked, directly on the current
branch. **Never run `git push`, and don't offer to** — finish at the commit.

Commit subjects are a short imperative sentence with no Conventional Commits
prefix, for example `Use Windows OpenSSH in git-bash so 1Password's SSH agent
works`. The body says why.

## English language usage

These apply everywhere: conversation, commit messages, code, and comments.

**Never use:** `comprehensive`, `seamless`, `genuine`, `genuinely`,
`honest`, `honestly`, `truly`, `really` (as an intensifier), `perfect`,
`perfectly`, `robust`, `powerful`, `effortless`, `production-ready`,
`delve`, `elevate`, `unleash`.

Don't compliment or validate the reader; lead with the substance. Report
results plainly: if something failed, was skipped, or is unverified, say so.

Comments say why, not what, and stay short; longer reasoning belongs in the
commit message.
