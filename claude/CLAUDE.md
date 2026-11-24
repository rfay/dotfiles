# User preferences

- Whenever you suggest a `git push` command for the user to run, say which host the checkout is on (the `hostname` output) and start the command block with `cd <absolute path to the checkout>`.
- Name new branches with the standard DDEV convention, `YYYYMMDD_<username>_<short_description>` (for example `20250108_rfay_fix_networking`), not session-generated names like `claude/...`. When updating an existing PR, push to that PR's own branch rather than creating a new one.
- In a `ddev/ddev` checkout, push branches for PRs to my fork `rfay/ddev` through a git remote named `rfay`, never to `origin`. Open the PR against `ddev/ddev` with `--head rfay:<branch>`. The same pattern applies to other repos I have forks of (`rfay/<repo>`, remote `rfay`).
  - URL: `git@github.com:rfay/<repo>` on my machines and coder workspaces, where SSH goes through my agent. Where git reaches GitHub only through the session's HTTPS proxy (for example the `macos-claude` runner), use `https://github.com/rfay/<repo>` after attaching `rfay/<repo>` to the session.
  - I approve pushes by reading the command, so it has to look like what I'd type. Add the remote as a separate command, never in the same command as a push. Push with one plain `git push -u rfay <branch>`, `git push rfay <branch>`, or `git push --force-with-lease rfay <branch>`, with no `&&`, `;`, pipes, loops, `sleep`, variables, `cd` or `bash -c`. If the cwd isn't the checkout, use `git -C <absolute path>`, except where the repo says its `ask` rule needs the plain form.
  - Just before the push, tell me in a line or two the branch, the remote URL, the commits (from a separate `git log --oneline`), and whether it's a force push and why.
  - On a network error, tell me and run the same command again as a new call. Never write a retry loop.
- When you need a temporary directory, use ~/tmp
- Avoid the word "Comprehensive". It just shows AI writing.
- Avoid saying "works perfectly".
- Avoid saying "You're absolutely right"
- When you need to run a bash command that does not start with the script or executable, you have to surround the command with `bash -c "..."`. This doesn't apply to git: run git directly, with `git -C <path>` instead of `cd`.
- Do not say "perfect" in response to actions. Do not claim that a particular result is "ready for production use"
- Prefer require to assert in tests
- Prefer t.Cleanup() to defer() in tests
- Prefer `jq` over Python for JSON/shell data processing
- To find approved GitHub PRs, never rely on `review:approved`, `--review approved`, or `reviewDecision`. They are empty unless the repo requires approvals, which ddev repos don't. Check each reviewer's latest non-comment review instead:
  `gh pr list -R OWNER/REPO --state open --draft=false --limit 200 --json number,title,author,url,reviews --jq '.[] | select([.reviews | map(select(.state != "COMMENTED")) | group_by(.author.login)[] | max_by(.submittedAt) | .state] | index("APPROVED")) | "#\(.number)\t\(.author.login)\t\(.title)\t\(.url)"'`
  The same applies to "changes requested" (match `CHANGES_REQUESTED`).
