# Routes

One playbook per request type. Each step is written as
`capability — what to do inline if that capability is unavailable`.
Capability names resolve through [capabilities.md](capabilities.md).

Size S routes may collapse steps; size L routes must not skip any.

### Risk overlay (code-changing routes: bug, feature, refactor, chore)

The risk level from the orchestrator's section 3 adds steps to these routes; it never
removes any. In doubt, use the stricter level.

- **Low** — `plan` (a short task list is enough).
- **Medium** — `spec` and `plan`.
- **High** — `spec`, `plan`, `design` for every task with a pending decision, and a
  mandatory security review in validation.

On these routes, `verify` and `review` run as the validation block of the
orchestrator's section 7, on the committed HEAD, with each result recorded by
`cs-evidence`; `review` is therefore required at every size. The route is done only
when `cs-evidence verify` passes.

---

## question

1. `explore` — Locate the relevant code. Read the entry points and the code paths the
   question is about; follow calls rather than guessing from names.
2. **Answer** — Lead with the direct answer, then the evidence as `path:line` references.
   Say what you did not verify.

No edits. If the answer reveals a bug or a needed change, offer it as a next route.

---

## bug

1. `explore` — Find the code involved in the failing behavior.
2. `debug` — **Reproduce first.** Get a failing test, command, or log that shows the bug.
   If you cannot reproduce it, stop and report what you tried instead of guessing a fix.
3. `debug` — **Root cause.** Explain why it happens, in one or two sentences, before
   changing anything. Fix the cause, not the symptom.
4. `test` — Write a regression test and confirm it fails for the expected reason.
5. `implement` — Make the smallest change that fixes the root cause; the regression test
   now passes.
6. `verify` — Run targeted tests, then the wider suite and static checks.
7. `review` (size M/L) — Independent review of the diff.
8. **Report** — Root cause, fix, regression test, verification result.

---

## feature

1. `explore` — Map where the feature plugs in and find the nearest existing example to
   imitate (a similar endpoint, component, command).
2. `spec` (size L, or when requirements are unclear) — Pin down behavior, inputs/outputs,
   edge cases, and what is out of scope. Ask the user only about real decisions.
3. `plan` — Break the work into ordered tasks. For each: files touched, how it is
   verified. Mark which tasks are independent. Size L → **approval gate** here.
4. `design` (only when a task hinges on a lasting choice between reasonable approaches) —
   Record the decision as an ADR before implementing it and link it from the task.
5. `implement` — Execute tasks in order. Independent tasks touching disjoint files may go
   to parallel subagents. Follow the conventions of the example found in step 1.
6. `test` — Tests for the new behavior, including the edge cases from the spec.
7. `spec-sync` (when there is a spec or existing docs cover the change) — Align the spec
   and docs with what was built; report unexplained deviations as pending.
8. `verify` — Full verification commands.
9. `review` (size M/L) — Independent review of the full diff against the spec/plan.
10. `deliver` — Summarize; commit / open PR only if asked (gate for push/PR).

---

## refactor

1. `explore` — Find every caller and usage of what is changing.
2. `test` — **Safety net first.** Confirm existing tests cover the behavior being
   preserved; if not, add characterization tests before touching the code.
3. `plan` (size M/L) — Sequence the change into steps that each leave the build green.
4. `design` (only when the target structure is a lasting choice between reasonable
   approaches) — Record it as an ADR before implementing and link it from the plan.
5. `implement` — Apply step by step; run the safety-net tests after each step.
6. `verify` — Full verification. Behavior must be unchanged: no test expectations edited
   unless the user agreed to a behavior change.
7. `review` (size M/L) — Review focused on accidental behavior changes.
8. **Report** — What moved where, and evidence that behavior is unchanged.

---

## review

1. **Scope** — Determine the target: uncommitted diff, branch vs. base, a PR, or paths.
2. `explore` — Read enough surrounding code to judge the change in context.
3. `review` — Look for, in priority order: correctness bugs, security issues, data loss,
   concurrency problems, broken contracts, missing tests, then maintainability.
   For each finding: location, concrete failure scenario, suggested fix.
   Drop findings you cannot back with a concrete scenario.
4. **Report** — Findings ranked by severity. Do not edit code unless the user asks;
   then route the fixes as `bug` or `refactor`.

---

## chore

1. **Ground** — Identify the files involved and how the change will be validated
   (CI config lint, lockfile install, docs build, ...).
2. `implement` — Make the change. For dependency upgrades, read the changelog for
   breaking changes before bumping.
3. `verify` — Run whatever proves the change works (install, build, the affected tests).
4. **Report**.

---

## investigation

1. **Frame** — Turn the symptom into a question with a measurable answer
   ("p95 latency of `/orders` regressed from X to Y", "test Z fails ~1 in 10 runs").
2. `explore` — Gather evidence: logs, metrics, git history (`git log -S`, `git bisect`),
   profiles, repeated runs. Several independent hypotheses → parallel subagents.
3. `debug` — Form hypotheses and test each against evidence. Keep a short log of
   what was ruled out.
4. **Report** — Findings with evidence, confidence level, and recommended next route
   (`bug`, `refactor`, ...). Do not fix unless the user asks.
