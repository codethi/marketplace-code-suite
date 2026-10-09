---
name: code
description: Run the whole code-suite flow end to end — ground, classify, clarify once up front, then spec, plan, implement, test, verify, review and deliver. Stops at the orchestrator's approval gates by default; --auto runs without approval stops; --ate-plano stops after the plan.
argument-hint: "<task> [--auto | --ate-plano] [--pr]"
disable-model-invocation: true
---

# /code — full flow, one run

The user invoked `/code` to have a task carried from request to delivered result. The
mode (section 0) decides where it may stop:

- **default** — runs the flow and stops at the orchestrator's approval gates (e.g. the
  plan of a size L change) and at the hard stops below.
- **`--auto`** — consent to proceed through spec and plan without approval stops. Ask
  once, at the start; after that, keep going until done or until a hard stop below.
- **`--ate-plano`** — run up to the saved plan (and its ADRs), then stop for review.

Input: `$ARGUMENTS`

**Reference, not a second entry point.** The orchestrator
([../orchestrator/SKILL.md](../orchestrator/SKILL.md)) is the entry point and defines
the flow: task start with `cs-context` and `cs-evidence`, intake, risk, delegation and
commits, validation and the `cs-evidence verify` gate. This command runs that flow
in the mode below. Where the two differ, the orchestrator wins.

## 0. Parse

- Task: everything except the flags. If empty, ask what to do and stop.
- `--auto`: no approval stops (see above). Hard stops still apply.
- `--ate-plano`: stop after phase 3. Nothing is implemented, committed or pushed; the
  report shows the goal, spec, plan and ADRs (Proposed) saved under
  `.code-suite/<slug>/` and `docs/adr/`. It takes precedence over `--auto` and `--pr`.
- `--commit`: accepted for compatibility. On code-changing routes the orchestrator
  already commits each task locally on `feat/<slug>`.
- `--pr`: push the branch and open a pull request at the end, after
  `cs-evidence verify` passes. Passing it is the user's confirmation for the push and
  the PR.
- Without `--auto` or `--ate-plano`: default mode, with the orchestrator's gates.
- Without `--pr`: the run ends with local commits on `feat/<slug>` and a summary;
  nothing is pushed.

Track the phases below in the session's task list if one is available, and update it as
you go so the user can follow the run.

## 1. Ground, classify, size

Follow sections 1–3 of the orchestrator: [../orchestrator/SKILL.md](../orchestrator/SKILL.md).
Resolve capabilities with [../orchestrator/references/capabilities.md](../orchestrator/references/capabilities.md)
and take the route from [../orchestrator/references/routes.md](../orchestrator/references/routes.md).

For a `question`, `review` or `investigation` route, run it as written there and report;
they make no changes, so phases 3–6 below do not apply.

## 2. Clarify once

This is the only planned interaction. Start the task and run `intake` as the
orchestrator's section 4 describes (stop on a dirty tree, a missing `test_cmd`, or an
unanswered high-risk gap). Explore first (`explore`), then collect every decision that
is genuinely the user's (product behavior, scope, costly trade-offs), as the `spec`
skill describes. Then:

- If there are any, ask them all in one batch with recommended options first, and wait.
- If there are none, do not ask. Announce the run in a few lines and start:

```text
Route: feature · L — explore → spec → plan → implement → test → verify → review → deliver
Assumptions: <inferable decisions you made>
Delivery: summary only | commit | PR
```

## 3. Spec and plan

- `spec`: for the steps the risk overlay requires, or size L or unclear requirements,
  write the spec and show it. With `--auto`, continue without waiting: the answers
  from step 2 are its confirmation. Otherwise wait where the orchestrator gates.
- `plan`: write the plan and show it. With `--auto`, continue; otherwise stop at the
  orchestrator's plan gate (size L). Use parallel `implementer` subagents for
  independent tasks with disjoint files.
- `design`: for a task that hinges on a lasting choice between reasonable approaches,
  write the ADR — Accepted with `--auto`, Proposed otherwise — link it from the plan,
  and list it under decisions in the report.

With `--ate-plano`, stop here and go to the report.

## 4. Build

Execute the route's remaining build steps (`debug`, `test`, `implement`) as written in
routes.md, task by task, keeping the build green after each.

## 5. Verify and review loops

1. **Verify** (`verify`). If it fails because of this change, fix the cause (`debug`
   when the cause is not obvious) and verify again.
2. **Review** (`review`, size M/L). Evaluate each finding; fix confirmed ones, record
   rejected ones with the reason. If you changed code, verify again.

Run these as the orchestrator's validation block (section 7), recording each result with
`cs-evidence`. Cap: two correction rounds. If validation still fails after that, stop
and go to the report with the failure; do not deliver it as done.

Pre-existing failures unrelated to the change are reported, not fixed.

## 6. Deliver

`spec-sync` runs before phase 5 (after the build), so its doc changes are validated in
the same commit. Pending divergences where the code is wrong go back to phase 4; ones
that need the user's decision are listed under follow-ups.

Run `cs-evidence verify <slug>` (`--high-risk` if high risk); only with exit 0 is the
work done. Then run `deliver` with the delivery mode from step 0. Never push or open a PR without `--pr`.

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
