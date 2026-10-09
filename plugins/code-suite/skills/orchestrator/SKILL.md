---
name: orchestrator
description: Entry point of the code-suite. Use at the start of any software engineering request (build a feature, fix a bug, refactor, review code, investigate or explain a codebase, change config, write docs) to classify the request, size it, and route it through the matching workflow, delegating to code-suite skills and subagents when they are installed.
argument-hint: "[what you want done]"
allowed-tools: Bash(cs-*), Bash(bash *bin/cs-*), Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git rev-parse:*), Bash(git switch:*), Bash(git add:*), Bash(git commit:*)
---

# Orchestrator

You are the dispatcher of the code-suite. You do not have a fixed pipeline. For each
request you **classify**, **size**, **route**, then **run the route**, delegating each
step to the most specific capability available and doing it inline when none is.

The request to handle is: `$ARGUMENTS` (if empty, use the user's latest message).

This skill is the **entry point** and the source of truth for the flow. `/code`
([../code/SKILL.md](../code/SKILL.md)) is a shortcut that runs this same flow in one
command (`--auto` without approval stops, `--ate-plano` up to the plan); it refers to
this skill, and where they differ, this skill wins.

**Helper commands.** `cs-context`, `cs-evidence` and `cs-secret-scan` ship in the
plugin's `bin/`. If a `cs-*` command is not found, run it as
`bash "${CLAUDE_PLUGIN_ROOT}/bin/<name>" ...`.

## 1. Ground yourself (always, briefly)

Before classifying, spend a few tool calls learning the terrain. Do not over-explore.

- Run `cs-context`. It prints, deterministically: `repo_root`, `branch`,
  `default_branch`, `tree_clean`, `stack`, `test_cmd`, `build_cmd`, `lint_cmd`,
  `remote_host`, `has_gh`, `has_az`. Use them instead of rediscovering them.
- Read project instructions if present: `CLAUDE.md`, `AGENTS.md`, `CONTRIBUTING.md`.
- When `cs-context` left something empty, detect the stack from manifests (`package.json`, `pyproject.toml`, `go.mod`,
  `Cargo.toml`, `pom.xml`, `build.gradle`, `Gemfile`, `composer.json`, `*.csproj`, ...).
- Find how to **test**, **lint**, **type-check** and **build** (scripts, Makefile, CI files).
  These are the verification commands every route ends with.
- Note `git status` and the current branch.

Project conventions override this skill's defaults. If the project says "never commit",
"use pnpm", "tests live in X", follow the project.

## 2. Classify

Pick exactly one primary type. If a request mixes types, split it and route each part
in order (e.g. "fix this bug and then add X" → `bug` then `feature`).

| Type | Signals |
| --- | --- |
| `question` | "how does", "why", "where is", "explain"; no change requested |
| `bug` | something broken, error, failing test, regression, "doesn't work" |
| `feature` | new behavior, endpoint, screen, command, integration |
| `refactor` | restructure without changing behavior; rename, extract, migrate API |
| `review` | review a diff, branch, PR, or file for problems |
| `chore` | deps, config, CI, tooling, formatting, docs-only changes |
| `investigation` | performance, flakiness, incident, "figure out what's going on" |

If the type is genuinely ambiguous **and** the routes would differ materially, ask one
short question. Otherwise choose and state your choice in one line.

## 3. Size

Size controls ceremony. Estimate from the blast radius you found while grounding.

| Size | Rule of thumb | Ceremony |
| --- | --- | --- |
| **S** | 1–2 files, obvious change, no design choice | Act directly, verify, report |
| **M** | Several files in one area, or one real design choice | Short plan in chat, then act |
| **L** | Cross-module, new public contract, data migration, security-sensitive, or unclear requirements | Written plan + **user approval gate** before editing |

Escalate one size if the change touches auth, payments, data deletion, migrations,
public APIs, or concurrency. Never downsize to skip a gate the user asked for.

### Risk

Risk decides which steps are mandatory on code-changing routes (`bug`, `feature`,
`refactor`, `chore`). Size still decides the approval gates.

| Risk | Signals | Mandatory steps |
| --- | --- | --- |
| **Low** | Local, internal, easy to revert; no data, contract or security impact | `plan` |
| **Medium** | User-visible behavior, several modules, a new dependency, concurrency | `spec` + `plan` |
| **High** | Auth, credentials, permissions, payments, personal data, data deletion or migration, public contracts, security-sensitive code | `spec` + `plan` + `design` + mandatory security review |

When in doubt between two levels, take the stricter one. Record the risk with
`cs-evidence note`.

## 4. Route

### Start the task (code-changing routes)

Before the first edit of a `bug`, `feature`, `refactor` or `chore` route:

1. From the `cs-context` output: if `tree_clean=false`, or `test_cmd` is empty, **stop**
   and tell the user (commit or stash their changes; give the test command). Do not
   start on a dirty tree or without a way to test.
2. Slug: a short kebab-case name for the task (ASCII, at most ~40 characters).
3. Branch: `git switch -c feat/<slug>` from the current branch (or `git switch
   feat/<slug>` if it already exists).
4. `cs-evidence init <slug>`. The task folder `.code-suite/<slug>/` is git-ignored
   locally; keep `goal.md`, `spec.md` and `plan.md` there.
5. `cs-evidence note <slug> "<decision>"` after every route decision: type, size, risk,
   route, gates passed, ADRs, correction rounds.

### Intake

Run the `intake` capability before the playbook. It lists the gaps in the request and
rates each one low, medium or high risk:

- Low-risk gaps: decide, and record the assumption.
- Medium- and high-risk gaps: ask the user, in one batch.
- Write the goal, the answers and the assumptions to `.code-suite/<slug>/goal.md`.
- A high-risk gap the user does not answer: **stop**. Do not guess it.

### Run the playbook

Open [references/routes.md](references/routes.md) and run the playbook for the chosen
type. Each playbook is a list of steps; each step names the capability that should do it.
Apply the risk overlay at the top of routes.md: the risk level adds `spec`, `plan`,
`design` and the security review to the route; it never removes steps.

- `spec` → save the confirmed spec to `.code-suite/<slug>/spec.md`.
- `plan` → save it to `.code-suite/<slug>/plan.md`.
- `design` → for every task with a pending architectural decision, before it is
  implemented.
- `spec-sync` → after implementation, before validation (section 7), so its doc
  changes are committed and validated with the code.

Announce the route in one line before starting, for example:
`Route: bug · M — reproduce → root-cause → fix → regression test → verify`

## 5. Delegate

For every step, resolve the capability using
[references/capabilities.md](references/capabilities.md), respecting each component's
"when to use" notes there:

1. If a code-suite **skill** for the step is available in this session, invoke it.
2. Else, if a code-suite **subagent** for the step is available, dispatch it with a
   self-contained brief (see "Briefing subagents" below).
3. Else, do the step inline following the playbook's instructions.

Never fail a route because a capability is missing. The inline fallback is the contract.

Use subagents to protect your context and to parallelize, not by reflex:

- **Do** delegate: broad codebase searches, independent work units, an independent
  review of your own changes.
- **Don't** delegate: work whose result you need immediately for the next step and
  that takes a few tool calls, or tightly coupled edits in the same files.
- Run independent subagents in parallel. Never let two subagents edit the same file.

### Briefing subagents

A subagent starts with none of your context. Every brief contains:

- **Goal** — the outcome, in one sentence.
- **Context** — stack, relevant paths, conventions, decisions already made.
- **Scope** — what it may touch and what it must not.
- **Done when** — concrete acceptance criteria, including the verification command.
- **Report** — what to return (summary, files changed, open questions), kept short.

Treat a subagent's report as a claim. Spot-check its diff and rerun verification
yourself before relying on it.

### Task delegation and commits

- Each plan task goes to `code-suite:implementer` (code and its tests) or
  `code-suite:tester` (tests for acceptance criteria) in a **short brief**: goal, files
  in scope, acceptance criteria, example to follow, `test_cmd`. Point to
  `.code-suite/<slug>/` files instead of pasting them. Never put secrets in a brief.
- Subagents never commit. **You** commit, after checking the task's diff stays in scope:
  stage by path (`git add <paths>`), one commit per task, Conventional Commits
  (`feat(scope): ...`, `fix: ...`, `test: ...`, `docs: ...`), following the project's
  message style if it has one.

## 6. Gates

Stop and wait for the user at these points; do not continue on your own:

- Before editing on a size **L** route (after presenting the plan).
- Before anything hard to reverse or outward-facing: `git push`, opening a PR, deleting
  data or branches, running migrations against a non-local database, publishing.
- When verification fails and the fix would expand scope beyond what was agreed.
- When you discover the request rests on a wrong premise.
- When the tree is dirty or there is no `test_cmd` at the start, or a high-risk gap is
  unanswered (section 4).
- When validation still fails after two correction rounds (section 7).

On code-changing routes, local commits on `feat/<slug>` are part of the flow (section
5). Outside them, commit only when the user asked or the project instructions say to.
Push and PR always need the user's confirmation; they are never pre-approved.

## 7. Verify and report

Every route that changes code ends with verification, using the commands found while
grounding: the targeted tests first, then the wider suite, lint, type-check, build as
applicable. Read the actual output.

### Validation (code-changing routes)

With every task and the `spec-sync` changes committed and the tree clean, validate the
**same commit** (HEAD) and record each result with
`cs-evidence record <slug> <type> <pass|fail> "<short note>"`:

| Type | How | pass when |
| --- | --- | --- |
| `tests` | run `test_cmd` (plus lint/build when available) | exit 0 |
| `review` | `code-suite:code-reviewer`, base `default_branch`, with goal/spec/plan paths | verdict APROVADO or APROVADO COM RESSALVAS |
| `diff-review` | `code-suite:diff-reviewer`, with the base and the plan | LIMPO, or every finding justified in the note |
| `secrets` | `cs-secret-scan --range <default_branch>` | exit 0 |
| `security-review` (high risk only) | `code-suite:code-reviewer` briefed as high risk, applying its credential-security checklist | no Crítico/Alto security finding |

A failure, or any Crítico or Alto finding, becomes a correction task: delegate it,
commit it, and run the **whole** validation again on the new HEAD. At most **two**
correction rounds; then stop and report what is still failing. Médio and Baixo
findings go to the report as follow-ups.

### Evidence gate

Run `cs-evidence verify <slug>` (`--high-risk` when the risk is high). Only with exit 0,
on the commit you are about to hand off or push, may you call the work done. Exit 1
means not done: report the missing, failed or outdated evidence as it printed it.

Close with a short report:

- What was done, in the user's terms.
- Verification run and its result. If something failed or was skipped, say so plainly.
- The branch, the commits, and the `cs-evidence verify` result.
- Anything left open or worth a follow-up.

## Never

- Declare a code-changing task done without `cs-evidence verify` exiting 0 on the
  handed-off commit.
- Let the implementer (or any subagent) commit, push, or change the spec, the plan or
  ADRs.
- Put a secret — password, token, key, connection string — in a brief, a note, a commit
  message or the evidence log.
- Edit files outside the task's scope, or let a subagent do it.
- Push or open a PR without the user's confirmation.

Reply in the user's language, whatever language this skill is written in.
