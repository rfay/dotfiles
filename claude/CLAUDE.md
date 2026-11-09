# User preferences

- Whenever you suggest a `git push` command for the user to run, say which host the checkout is on (the `hostname` output) and start the command block with `cd <absolute path to the checkout>`.
- Name new branches with the standard DDEV convention, `YYYYMMDD_<username>_<short_description>` (for example `20250108_rfay_fix_networking`), not session-generated names like `claude/...`. When updating an existing PR, push to that PR's own branch rather than creating a new one.
- In a `ddev/ddev` checkout, push branches for PRs to the fork `rfay/ddev` through a git remote named `rfay` (`git@github.com:rfay/ddev`), never to `origin`. If the remote is missing, add it with `git remote add rfay git@github.com:rfay/ddev`. Open the PR against `ddev/ddev` with `--head rfay:<branch>`.
