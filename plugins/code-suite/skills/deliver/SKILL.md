---
name: deliver
description: code-suite `deliver` capability. Use when finished work is ready to hand off — to check the diff is clean, summarize it, and, only when the user asks, commit, push or open a pull request following the project's conventions. Used at the end of the orchestrator's routes; also usable directly.
argument-hint: "[summary | commit | pr]"
---

# Deliver

Hand off finished work cleanly. By default, delivering means a clean diff and a clear
summary. Committing, pushing and opening PRs happen only when the user asks for them
(or the project instructions say to).

Requested action: `$ARGUMENTS` (if empty: summary only).

## 1. Pre-flight

- Verification has run on the final state of the code and passed. If not, run the
  `verify` capability first. Do not deliver red work without saying so up front.
- Inspect `git status` and the full `git diff`:
  - Only intended files changed. No debug logs, scratch scripts, commented-out code,
    stray formatting churn, or unrelated edits.
  - No secrets, credentials, tokens, `.env` contents or personal data.
  - Generated files and lockfiles changed only when they should have.

## 2. Summary

Write for the user:

- **What changed** — in their terms, grouped by behavior, not by file.
- **Verification** — commands run and results.
- **Notes** — decisions made, follow-ups, anything skipped or still failing.

## 3. Commit (only when asked)

- If on the default branch and the project uses feature branches, create a branch first.
- Match the project's message style; read `git log --oneline -15`
  (e.g. Conventional Commits, ticket prefixes, language).
- Stage files explicitly by path; avoid `git add -A` unless the diff was fully reviewed.
- One logical change per commit. The message says why, not just what.
- Include any attribution lines the session or project requires.
- Never bypass hooks (`--no-verify`) or amend/rewrite published commits unless the user
  asks. If a pre-commit hook fails, fix the cause and create the commit again.

## 4. Push and pull request (only when asked — confirm first)

Pushing and opening a PR are outward-facing. Confirm with the user before doing either,
unless they explicitly asked for it in this request.

- Never force-push to a shared branch without an explicit request.
- Use the platform CLI if available (e.g. `gh pr create`); otherwise give the user the
  branch name and the PR text.
- PR body: summary of the change, why, how it was tested, risks or rollout notes, and
  links to issues. Follow the repository's PR template if one exists.

## 5. Report

Final message: the summary from step 2, plus the commit hashes, branch and PR URL for
whatever was done.
