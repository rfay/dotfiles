---
name: writeup
description: Write a markdown summary of the current work into ~/tmp, such as a PR's history and status, what was learned in an investigation, or an analysis of CI logs, so it can be read later or handed to another session. Use for "write a full summary of what has been done and its status", "write this explanation to a markdown file in ~/tmp", "write this analysis into ~/tmp/x.md", "write a short summary of what we've learned".
---

# Write a summary to ~/tmp

## Where

Use the path the user gives. Otherwise
`~/tmp/<YYYYMMDD>_<short_topic>.md`, e.g. `~/tmp/20260205_multiple_certs.md`.
Never put it in the repo. Print the full path at the end.

## What

Write for a reader with no access to this session, including a later Claude
session that will be pointed at the file:

1. **Status** first: one paragraph on where things stand now and what is
   blocking.
2. **Context**: the issue/PR/branch, with links and the repo path.
3. **What was done**: by commit or step, with SHAs, and why each was needed.
4. **What was learned**: facts established, with evidence (links, log lines,
   `file:line`). Separate confirmed findings from hypotheses.
5. **Open questions and next steps.**

Drop dead ends unless knowing they failed saves the next reader time; then
give each one a line. A "short summary" means a few paragraphs, not this full
structure.

If the user then corrects a claim, fix the file and show the changed part.
