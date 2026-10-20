---
name: gh-comment
description: Post a comment on a GitHub issue, pull request, or security advisory, written by Claude and labeled as such. Use for "add a comment to the PR explaining this", "comment on https://github.com/.../issues/N", "add a summary of the problem to the PR", "make that comment on the PR (identify yourself)", "open an issue about this".
---

# Comment on GitHub

Posting is public and hard to take back. Post only when the user asked for a
comment in this request; otherwise show the draft.

## Write it

- First line identifies the author: `_Comment by Claude Code, at @rfay's
  request._` (or as the user words it).
- Lead with the conclusion, then the evidence: failing run links, `file:line`
  references, commit SHAs, and links to every outside source used. Someone who
  hasn't read this session must be able to act on it.
- Keep it short. Follow the repo's AGENTS.md language rules if it has any.
- Write the body to a file; never pass it inline through `$(...)`.

## Post it

```bash
gh issue comment <n> --repo <o>/<r> --body-file ~/tmp/comment.md
gh pr comment <n> --repo <o>/<r> --body-file ~/tmp/comment.md
gh issue create --repo <o>/<r> --title "..." --body-file ~/tmp/issue.md
```

For a security advisory (`/security/advisories/GHSA-...`), `gh` has no comment
command and the REST API doesn't support advisory comments: give the user the
text to paste, and say so.

Print the URL of what was posted.
