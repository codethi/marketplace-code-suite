---
name: design
description: code-suite `design` capability. Use before implementing a task that hinges on a lasting architectural choice between more than one reasonable approach (algorithm, library, pattern, data format), to record the decision as an ADR in docs/adr/ and link it from the plan. Skip it for obvious or cheaply reversible choices. Used by the orchestrator's feature and refactor routes; also usable directly.
argument-hint: "[decision to record]"
---

# Design

Record an architectural decision as an ADR (Architecture Decision Record) **before**
implementing it, so the choice, the alternatives and the trade-offs survive the
conversation. One decision per ADR, one page.

The decision: `$ARGUMENTS` (if empty, use the conversation so far, including the plan).

## 1. Gate: does this deserve an ADR?

Write one only when **all** of these hold:

- **More than one reasonable approach.** You could defend at least two options in this
  repository, not one real option and a straw man.
- **Lasting consequence.** Reversing it later is expensive: it adds a dependency, fixes a
  persisted data format or public contract, sets a pattern other code will copy, or
  spreads across many files. Typical cases: choosing an algorithm, a library, a pattern
  (sync vs. event-driven, inheritance vs. composition), a data or storage format.
- **Not already decided.** No existing ADR, project instruction or established
  convention in the code settles it.

Do not write an ADR for naming, for following an existing pattern, for local
refactors, or for anything you could undo in one small commit. Make those choices,
mention them in the report, and move on. If the gate fails, say so in one line and
return to the route.

## 2. Ground the options

- Read the code the decision affects and the constraints around it: existing
  dependencies, runtime/platform, data already stored, performance or compatibility
  requirements. Use the `explore` capability (`code-suite:code-explorer` when
  available) if the area is unfamiliar.
- Read the existing ADRs. If one already covers this, follow it. If the new decision
  replaces one, say so in Context and link it.
- Keep 2–4 options. Judge each **in the context of this repository** — what it costs
  here, what it fits or fights in this codebase — not by generic reputation.

## 3. Locate and number

- Use the project's existing ADR directory and format if there is one (for example
  `docs/adr/`, `doc/adr/`, `docs/decisions/`, or the path in an `.adr-dir` file).
  Otherwise use `docs/adr/`.
- Number = highest existing `NNNN-*.md` number + 1, as 4 digits; the first is `0001`.
  Never reuse or fill gaps in numbers.
- File name: `NNNN-<title-in-kebab-case>.md`, ASCII, lowercase,
  e.g. `docs/adr/0004-use-sqlite-for-local-cache.md`.

## 4. Write the ADR

Write in the language of the project's existing docs (English if there are none). Keep
it to one page: if it runs longer, it is covering more than one decision — split it.

```markdown
# NNNN. <The decision, as a short phrase>

- **Status:** Proposed | Accepted
- **Date:** YYYY-MM-DD

## Context

<The problem and the forces at play in this repository: constraints, requirements,
what exists today. Link the plan task or spec. 3–6 sentences.>

## Considered options

### <Option A>

- Pro: <concrete, specific to this codebase>
- Con: <concrete, specific to this codebase>

### <Option B>

- Pro: ...
- Con: ...

## Decision

<The chosen option and the deciding reason, in 1–3 sentences: "We will use B because …".>

## Consequences

- <What becomes easier.>
- <What becomes harder, or the cost accepted.>
- <Follow-ups this creates (migrations, docs, things to revisit), if any.>
```

## 5. Set the status

- **Proposed** — the choice is the user's to make (cost, product impact, team-wide
  convention), or the route is size L. Present the options and your recommendation in
  a few lines, link the ADR, and wait. When the user agrees, change it to **Accepted**;
  if they pick another option, rewrite Decision and Consequences first.
- **Accepted** — the user already agreed, or delegated the decision (for example in a
  `/code` run). List the ADR among the decisions in your report.

Do not implement a decision whose ADR is still Proposed.

## 6. Link it from the plan

Update the plan task the decision belongs to with a link to the ADR, e.g.
`[ADR-0004](docs/adr/0004-use-sqlite-for-local-cache.md)`:

- Plan in a file → edit that task's row.
- Plan in the conversation or the session's task list → update the task there.
- No plan → mention the ADR in the summary.

Then return to the route and implement according to the ADR. If implementation shows
the decision was wrong, stop: update the ADR while it is Proposed, or write a new ADR
that supersedes an Accepted one (adding `Superseded by NNNN` under the old one's
Status), and tell the user.
