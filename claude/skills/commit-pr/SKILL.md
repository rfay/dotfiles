---
name: commit-pr
description: Commit work and open a pull request in any repository, following that repo's own conventions (its commit skill, AGENTS.md, or .github/PULL_REQUEST_TEMPLATE.md). Use for "commit this", "commit with the PR template", "add a new commit", "create a PR", "create a draft PR", "update the PR description", "I pushed this to the rfay remote, create a PR".
---

# Commit and open a PR

## 1. Find the repo's own rules first

A repo's rules override this file. Check, in order:

1. A project commit skill, e.g. `.claude/skills/*commit*/SKILL.md`. If one
   exists, read it and follow it instead of the rest of this file.
2. `AGENTS.md` / `CLAUDE.md` for commit format, required checks, and remotes.
3. `.github/PULL_REQUEST_TEMPLATE.md` (or `.github/pull_request_template.md`).

## 2. Run the repo's checks before committing

Use the repo's own entry points: `make` and `make staticrequired` for Go repos
that have them, `ddev prettier`/`ddev textlint` for content repos, and the
test the change touched. Report a failure; don't commit around it.

## 3. Commit

- **Stage only the files for this change.** Leave unrelated edits (a local
  Makefile tweak, CLAUDE.md, debug output) unstaged unless asked. If the user
  says they already ran `git add`, commit what is staged and nothing else.
- **Add a new commit; never amend** unless the user says "amend". Amending a
  pushed commit forces a force-push and has broken CI before.
- **Write the message to a file and use `git commit -F <file>`.** Inline
  heredocs inside `$(...)` mangle markdown.
- When asked to use the PR template for the message, keep its `##`/`###`
  headings verbatim and fill every section. A subject line goes first,
  then a blank line, then the template body. Dropping the headings is the
  most common mistake here; check the file before committing.
- Reference issues as the user asks (`fixes #10, fixes #22`, `closes #135`)
  and link the failing CI run when the commit fixes one.
- Put `[skip ci]` or `[skip buildkite]` in the subject only when asked.
- When the user asks for credit, say in the body that Claude did the work.
- Show `git log --stat -1` afterward.

**Never push**, and don't offer to. The user pushes.

## 4. Create the PR (only after the user says it's pushed)

Work out where the branch lives. The user's fork remote is usually `rfay`;
the canonical repo is `upstream` (or `origin` when there is no fork):

```bash
git remote -v
branch=$(git branch --show-current)
git ls-remote --heads rfay "$branch"   # confirm it was pushed, and where
```

Fill the PR template from the commits since the base
(`git log upstream/main..HEAD`), not only the latest one. Write the body to a
file and create the PR against the canonical repo:

```bash
gh pr create --repo <owner>/<repo> --base main --head rfay:"$branch" \
  --title "<title in the repo's format>" --body-file ~/tmp/pr_body.md [--draft]
```

Use `--draft` when the user says draft, or when the PR is not meant to merge
as-is (then say so in the summary). To update an existing PR's description,
use `gh pr edit <n> --body-file`. Print the PR URL at the end.
