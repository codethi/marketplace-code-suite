---
name: code
description: Run the whole code-suite flow end to end in one go — ground, classify, clarify once up front, then spec, plan, implement, test, verify, review and deliver without stopping between phases.
argument-hint: "<task> [--commit] [--pr]"
disable-model-invocation: true
---

# /code — full flow, one run

The user invoked `/code` to have a task carried from request to delivered result in a
single run. Invoking it is their consent to proceed through the spec and plan phases
without approval stops. Ask once, at the start; after that, keep going until done or
until a hard stop below.

Input: `$ARGUMENTS`

## 0. Parse

- Task: everything except the flags. If empty, ask what to do and stop.
- `--commit`: commit the result at the end (via `deliver`).
- `--pr`: commit, push a branch and open a pull request at the end. Implies `--commit`.
  Passing it is the user's confirmation for the push and the PR.
- No flags: the run ends with a clean diff and a summary; nothing is committed.

Track the phases below in the session's task list if one is available, and update it as
you go so the user can follow the run.

## 1. Ground, classify, size

Follow sections 1–3 of the orchestrator: [../orchestrator/SKILL.md](../orchestrator/SKILL.md).
Resolve capabilities with [../orchestrator/references/capabilities.md](../orchestrator/references/capabilities.md)
and take the route from [../orchestrator/references/routes.md](../orchestrator/references/routes.md).

For a `question`, `review` or `investigation` route, run it as written there and report;
they make no changes, so phases 3–6 below do not apply.

## 2. Clarify once

This is the only planned interaction. Explore first (`explore`), then collect every
decision that is genuinely the user's (product behavior, scope, costly trade-offs), as
the `spec` skill describes. Then:

- If there are any, ask them all in one batch with recommended options first, and wait.
- If there are none, do not ask. Announce the run in a few lines and start:

```text
Route: feature · L — explore → spec → plan → implement → test → verify → review → deliver
Assumptions: <inferable decisions you made>
Delivery: summary only | commit | PR
```

## 3. Spec and plan (no gates)

- `spec`: for size L or unclear requirements, write the spec, show it, and continue
  without waiting for confirmation. The answers from step 2 are its confirmation.
- `plan`: for size M/L, write the plan, show it, and continue. Use parallel
  `implementer` subagents for independent tasks with disjoint files.

## 4. Build

Execute the route's remaining build steps (`debug`, `test`, `implement`) as written in
routes.md, task by task, keeping the build green after each.

## 5. Verify and review loops

1. **Verify** (`verify`). If it fails because of this change, fix the cause (`debug`
   when the cause is not obvious) and verify again.
2. **Review** (`review`, size M/L). Evaluate each finding; fix confirmed ones, record
   rejected ones with the reason. If you changed code, verify again.

Cap: three verify-fix cycles in total. If checks are still red after that, stop the
loop and go to the report with the failure; do not deliver it as done.

Pre-existing failures unrelated to the change are reported, not fixed.

## 6. Deliver

Run `deliver` with the delivery mode from step 0. Never push or open a PR without `--pr`.

## Hard stops

Stop and ask, even mid-run, only when:

- The task rests on a wrong premise, or the requested change is impossible as stated.
- Doing it right requires clearly more scope than requested (another service, a public
  contract change, a data migration) that was not covered in step 2.
- An action is destructive or outward-facing beyond what the flags allow: deleting data
  or branches, migrations against a non-local database, publishing, force-pushing.
- The verify-fix cap is reached.

Everything else — naming, structure, which existing pattern to follow, how to test —
you decide, following the project's conventions, and list in the report.

## Report

End with one message:

- **Done** — what changed, in the user's terms.
- **Route** — type, size, and the phases that ran.
- **Decisions & assumptions** — what you decided without asking.
- **Verification** — commands and results; anything skipped or still failing, plainly.
- **Review** — findings fixed, findings rejected and why.
- **Delivery** — commits, branch, PR URL, or "not committed".
- **Follow-ups** — anything left open.

Reply in the user's language.
