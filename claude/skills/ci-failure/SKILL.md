---
name: ci-failure
description: Diagnose a failing or intermittent CI job from a GitHub Actions run URL, a Buildkite build URL, or a downloaded log file. Use for "this test is failing, see https://github.com/.../actions/runs/...", "https://buildkite.com/...", "the log is in ~/Downloads/...", "fails intermittently", "works locally but fails in CI", "still failing after this commit".
---

# Diagnose a CI failure

## 1. Get the log

- **GitHub Actions** (`.../actions/runs/<run>/job/<job>`):
  `gh run view <run> --repo <o>/<r> --log-failed`, or
  `gh run view --job <job> --repo <o>/<r> --log` for one job. A `#step:N:L`
  fragment points at the line the user cares about.
- **Buildkite** (`buildkite.com/<org>/<pipeline>/builds/<n>#<job-uuid>/L123`):
  the job UUID is the URL fragment. Use
  `bk job log <job-uuid> --agent --no-timestamps` and
  `bk build view <n> -p <pipeline> --org <org>` for the job list. If `bk` is
  not authenticated, use `$BUILDKITE_API_TOKEN` with the REST API, or ask the
  user to download the log to `~/Downloads`.
- **Downloaded log**: logs are large; `grep -n` for `--- FAIL`, `FAIL:`,
  `panic:`, `Error`, `timed out`, then read around the first hit. Line numbers
  the user gives refer to the file.

## 2. Find the first real error

Later failures usually cascade from the first one. Quote the exact failing
assertion or panic with its `file:line`, and the test name.

## 3. Classify it

- **Regression**: fails consistently since a commit. Find the commit with the
  PR's run history (`gh run list --branch <b>`) or by comparing a passing run.
  Check whether the change was compared to `upstream/main` rather than a
  stale local `main`.
- **Intermittent**: passes locally, fails on some runners. The user's machine
  is fast, so suspect races and readiness checks that assume timing. Find
  what the test waits on and why it is not ready; don't propose a longer
  sleep or timeout unless you can show the operation is slow, not stuck.
- **Platform-specific**: compare which runners/providers fail (WSL2 NAT vs
  mirrored, Lima, Colima, OrbStack, Rancher Desktop, Podman, arm64 vs amd64).
  Tool syntax differs too (e.g. BSD vs GNU `nc`, `sed`, bash 3.2 on macOS).
- **Infrastructure**: GitHub API rate limiting, registry pulls, runner disk,
  a job timeout, or a dependency released minutes ago. Check the dependency's
  recent commits/releases and its issue queue before blaming our code.

## 4. Reproduce and fix

Run the single test locally with the repo's own command (for example
`GOTEST_SHORT=7 go test -v ./pkg/... -run '^TestName$'`). Explain the root
cause, then propose the fix and say how it will be confirmed in CI. When the
fix is a skip for one platform, guard only that platform.
