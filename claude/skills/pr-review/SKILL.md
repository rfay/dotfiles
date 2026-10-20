---
name: pr-review
description: Review a pull request or branch against its upstream base, including its linked issue, prior review comments, risks, test coverage, and optional manual testing. Use for "review this PR", "review #8311", "review https://github.com/.../pull/N", "do a final review", "are there any risks", "review and manually test this PR", "review the entire PR again (git diff upstream/main)".
---

# Review a PR

The review goes in the chat. **Do not post it to GitHub** unless the user asks;
they usually want to read it first.

## 1. Gather context

- PR given by number or URL: `gh pr view <n> --repo <owner>/<repo> --json
  title,body,author,baseRefName,headRefName,files,commits,reviews,comments`
  and `gh pr diff <n>`. Read the linked issue too (`gh issue view`).
- "Here" or "this branch": diff against the upstream base, not local `main`,
  which is often stale. Use `git fetch upstream` then
  `git diff upstream/main...HEAD` and `git log upstream/main..HEAD`. If there
  is no `upstream` remote, use `origin/main`.
- Read earlier review threads (`gh api repos/<o>/<r>/pulls/<n>/comments`) so
  you don't repeat points that are already resolved.
- Read the surrounding code, not only the hunks. Check callers of anything
  whose behavior changed.

## 2. What to look for

- Does it fix the stated problem, and the root cause rather than a symptom?
  Fixes that "wait longer" or retry for intermittent failures need a reason
  why the underlying operation is slow, not just a bigger timeout.
- Behavior change for existing users, existing config, and other platforms
  (macOS, Linux, WSL2, Windows, and Docker providers such as Lima, Colima,
  OrbStack, Rancher Desktop, Podman).
- Tests: is the change covered, do the tests test the intent, are they
  deterministic? Prefer `require` over `assert` and `t.Cleanup()` over `defer`
  in Go tests.
- Duplicated code that could reuse an existing helper; the repo usually has
  one already.
- Docs and release notes that the change makes wrong.
- Security, if the PR touches input parsing, archives, paths, or credentials.

## 3. Verify, don't guess

Build with the repo's own commands (`make`, `make staticrequired`) and run the
tests the PR touches. If the user asks for manual testing, follow the PR's
"Manual Testing Instructions" exactly, in a scratch project under `~/tmp` or a
project the user names, and report what you saw. Clean up projects you created.

## 4. Report

Lead with a one-paragraph verdict (merge, merge after fixes, or rework). Then
findings ordered by severity, each with `file:line`, what is wrong, and a
concrete fix. Keep nits separate and short. Say what you did not check.
