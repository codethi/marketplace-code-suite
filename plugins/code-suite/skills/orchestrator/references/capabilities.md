# Capability registry

The routes name **capabilities**, not concrete tools. This file maps each capability to
the code-suite component that provides it. Resolve in order: skill → subagent → inline,
subject to each component's "when to use" notes below.

A component is "available" if it appears in this session's list of skills or agent
types. Plugin components are listed as `code-suite:<name>`.

| Capability | Skill | Subagent | Inline fallback |
| --- | --- | --- | --- |
| `explore` | — | `code-suite:code-explorer` | Search with Grep/Glob, read entry points; for broad sweeps use a built-in read-only exploration agent if the session has one |
| `spec` | `code-suite:spec` | — | Write the spec in chat: behavior, I/O, edge cases, out of scope |
| `plan` | `code-suite:plan` | — | Ordered task list with files and verification per task |
| `implement` | — | `code-suite:implementer` | Edit directly, following the nearest existing example |
| `test` | `code-suite:test` | — | Write tests in the project's existing framework and style |
| `debug` | `code-suite:debug` | — | Reproduce → hypothesize → test hypothesis → root cause |
| `review` | — | `code-suite:code-reviewer` | Re-read the full diff as a skeptical reviewer, per the `review` route |
| `verify` | — | `code-suite:verifier` | Run the test / lint / type-check / build commands found while grounding |
| `deliver` | `code-suite:deliver` | — | Summarize; commit or open a PR only when asked |

`—` means there is no component of that kind for the capability.

Skills run in your context and can talk to the user. Subagents run isolated: they keep
noise out of your context and can run in parallel, but start with no context, so brief
them fully (see "Briefing subagents" in the orchestrator).

## Using the components

### `explore` → `code-suite:code-explorer` (subagent)

Dispatch it when the answer needs more than a few searches, or when several areas can be
mapped in parallel (one explorer per area or hypothesis). For a single known file, just
read it yourself.

Put the depth in the brief: `quick` (locate), `medium` (trace the main path; default) or
`thorough` (every caller, history, edge cases). Pass the stack and anything you already
know so it does not re-discover them. Example brief:

```text
Goal: Map how an order's status changes from "pending" to "paid".
Depth: medium
Context: NestJS monorepo, services under apps/. Payment webhooks enter via apps/payments.
Scope: Read-only. Ignore the admin UI.
Done when: The full path from webhook to DB write is traced with path:line, and the
tests covering it are listed.
Report: Use your standard report format.
```

It returns a map (entry points, flow, key files, example to follow, verification,
open questions). Open the cited `path:line` locations you are about to edit before
changing anything.

### `spec` → `code-suite:spec` (skill)

Invoke for size L features and whenever requirements are unclear. It asks the user only
the real decisions and ends with a confirmed spec. Do not proceed to `plan` until the
user confirms.

### `plan` → `code-suite:plan` (skill)

Invoke for size M/L changes. It produces the task table and the execution strategy; on
size L it is the approval gate. Pass it the spec and the explore map if you have them.

### `implement` → `code-suite:implementer` (subagent)

Not the default for every edit. Dispatch it when:

- the plan has **independent tasks with disjoint files** — one implementer per task, all
  in the same turn; or
- a task is large and self-contained enough that its exploration and iteration would
  flood your context.

Otherwise implement inline. The brief must include the task goal, the exact files it may
touch, the example to imitate, decisions already made, and the verification command.
It reports `done | blocked | partial`; review its diff and rerun verification yourself.
If it is blocked on an out-of-scope file, decide and re-dispatch or do it inline.

### `test` → `code-suite:test` (skill)

Invoke whenever tests are written outside an implementer: regression tests in the bug
route (before the fix), behavior tests for features, characterization tests before a
refactor. It enforces proving that each test can fail.

### `debug` → `code-suite:debug` (skill)

Invoke for the bug and investigation routes. In the investigation route, tell it the
user asked to find, not fix, so it stops after the root cause. It hands back to `test`
for the regression test.

### `review` → `code-suite:code-reviewer` (subagent)

Dispatch it for size M/L changes after verification passes, and for the review route.
Its independence is the point: do not pass your reasoning about why the code is
correct. Pass the target (uncommitted diff, branch vs. base, PR), the spec/plan if any,
and areas of concern. Evaluate each finding before acting on it: fix confirmed ones,
and tell the user about any you reject and why.

### `verify` → `code-suite:verifier` (subagent)

Dispatch it for full verification (whole suite, lint, type-check, build), where logs are
long. Running one targeted test inline while iterating is fine. Pass the commands you
found while grounding and the targeted tests. Treat `partial` or `skipped` as not
verified, and report it as such.

### `deliver` → `code-suite:deliver` (skill)

Invoke at the end of routes that changed code. Tell it what the user asked for:
summary only (default), commit, or PR. Push and PR still require user confirmation.

## Adding a component

When a new skill or subagent is added to the plugin:

1. Put it under `plugins/code-suite/skills/<name>/` or `plugins/code-suite/agents/<name>.md`.
2. Fill its cell in the table above with its exact name (`code-suite:<name>`) and add
   a "when to use" note under "Using the components".
3. Keep the inline fallback; it is what runs when the component is not installed.

Routes in [routes.md](routes.md) do not change when a capability gains a component.
