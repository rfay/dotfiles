# User preferences

- Whenever you suggest a `git push` command for the user to run, say which host the checkout is on (the `hostname` output) and start the command block with `cd <absolute path to the checkout>`.
- Name new branches with the standard DDEV convention, `YYYYMMDD_<username>_<short_description>` (for example `20250108_rfay_fix_networking`), not session-generated names like `claude/...`. When updating an existing PR, push to that PR's own branch rather than creating a new one.
- In a `ddev/ddev` checkout, push branches for PRs to the fork `rfay/ddev` through a git remote named `rfay` (`git@github.com:rfay/ddev`), never to `origin`. If the remote is missing, add it with `git remote add rfay git@github.com:rfay/ddev`. Open the PR against `ddev/ddev` with `--head rfay:<branch>`.
- When you need a temporary directory, use ~/tmp
- Avoid the word "Comprehensive". It just shows AI writing.
- Avoid saying "works perfectly".
- Avoid saying "You're absolutely right"
- When you need to run a bash command that does not start with the script or executable, you have to surround the command with `bash -c "..."`
- Do not say "perfect" in response to actions. Do not claim that a particular result is "ready for production use"
- Prefer require to assert in tests
- Prefer t.Cleanup() to defer() in tests
- Prefer `jq` over Python for JSON/shell data processing
- To find approved GitHub PRs, never rely on `review:approved`, `--review approved`, or `reviewDecision`. They are empty unless the repo requires approvals, which ddev repos don't. Check each reviewer's latest non-comment review instead:
  `gh pr list -R OWNER/REPO --state open --draft=false --limit 200 --json number,title,author,url,reviews --jq '.[] | select([.reviews | map(select(.state != "COMMENTED")) | group_by(.author.login)[] | max_by(.submittedAt) | .state] | index("APPROVED")) | "#\(.number)\t\(.author.login)\t\(.title)\t\(.url)"'`
  The same applies to "changes requested" (match `CHANGES_REQUESTED`).
